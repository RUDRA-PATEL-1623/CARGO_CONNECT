const { getPool } = require('../config/database');
const customerModel = require('../models/customer.model');
const paymentModel = require('../models/payment.model');
const shipmentModel = require('../models/shipment.model');
const shipmentCategoryModel = require('../models/shipmentCategory.model');
const notificationService = require('./notification.service');
const AppError = require('../utils/appError');

const DEFAULT_DISTANCE_KM = 10;
const AVERAGE_SPEED_KMPH = 32;
const SERVICE_FEE = 25;
const TAX_RATE = 0.18;
const WEIGHT_INCLUDED_KG = 10;
const WEIGHT_SURCHARGE_PER_KG = 4;

const roundMoney = (value) => Math.round((Number(value) + Number.EPSILON) * 100) / 100;

const generateCode = (prefix) => {
  const now = new Date();
  const datePart = now.toISOString().slice(0, 10).replace(/-/g, '');
  const randomPart = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
  return `${prefix}-${datePart}-${Date.now().toString().slice(-6)}${randomPart}`;
};

const getActiveCustomer = async (userId, connection = null) => {
  const customer = await customerModel.findByUserId(userId, connection);

  if (!customer || customer.accountStatus !== 'active') {
    throw new AppError('Active customer profile is required', 403);
  }

  return customer;
};

const getActiveCategory = async ({ categoryId, categoryCode }, connection = null) => {
  const category = categoryId
    ? await shipmentCategoryModel.findById(categoryId, connection)
    : await shipmentCategoryModel.findByCode(categoryCode, connection);

  if (!category || !category.isActive) {
    throw new AppError('Active shipment category was not found', 404);
  }

  return category;
};

const calculatePriceEstimate = async (payload, connection = null) => {
  const category = await getActiveCategory(payload, connection);
  const packageWeightKg = Number(payload.packageWeightKg || payload.weight);
  const estimatedDistanceKm = Number(
    payload.estimatedDistanceKm || DEFAULT_DISTANCE_KM,
  );

  if (category.maxWeightKg && packageWeightKg > category.maxWeightKg) {
    throw new AppError(
      `Package weight exceeds ${category.name} limit of ${category.maxWeightKg} kg`,
      422,
    );
  }

  const basePrice = roundMoney(category.basePrice);
  const distanceCharge = roundMoney(estimatedDistanceKm * category.pricePerKm);
  const excessWeight = Math.max(0, packageWeightKg - WEIGHT_INCLUDED_KG);
  const weightSurcharge = roundMoney(excessWeight * WEIGHT_SURCHARGE_PER_KG);
  const fragileCharge = payload.isFragile ? roundMoney(basePrice * 0.1) : 0;
  const subtotalAmount = roundMoney(
    basePrice + distanceCharge + weightSurcharge + fragileCharge,
  );
  const feeAmount = SERVICE_FEE;
  const taxAmount = roundMoney((subtotalAmount + feeAmount) * TAX_RATE);
  const totalAmount = roundMoney(subtotalAmount + feeAmount + taxAmount);
  const estimatedDurationMinutes = Math.max(
    20,
    Math.ceil((estimatedDistanceKm / AVERAGE_SPEED_KMPH) * 60),
  );

  return {
    category: {
      id: category.id,
      code: category.code,
      name: category.name,
      vehicleSuggestion: category.vehicleSuggestion,
      iconKey: category.iconKey,
    },
    estimatedDistanceKm,
    estimatedDurationMinutes,
    currency: 'INR',
    breakdown: {
      basePrice,
      distanceCharge,
      weightSurcharge,
      fragileCharge,
      subtotalAmount,
      discountAmount: 0,
      feeAmount,
      taxAmount,
      totalAmount,
    },
  };
};

const calculateCustomerPriceEstimate = async (userId, payload) => {
  await getActiveCustomer(userId);
  return calculatePriceEstimate(payload);
};

const normalizeDimensions = (dimensions = {}) => ({
  packageLengthCm: dimensions.lengthCm || dimensions.length || null,
  packageWidthCm: dimensions.widthCm || dimensions.width || null,
  packageHeightCm: dimensions.heightCm || dimensions.height || null,
});

const createShipmentRequest = async (userId, payload) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();
    const customer = await getActiveCustomer(userId, connection);
    const estimate = await calculatePriceEstimate(payload, connection);
    const category = await getActiveCategory(payload, connection);
    const dimensions = normalizeDimensions(payload.dimensions);

    const shipment = await shipmentModel.createShipment(
      {
        shipmentCode: generateCode('SHP'),
        customerId: customer.id,
        categoryId: category.id,
        pickupAddress: payload.pickupAddress,
        pickupCity: payload.pickupCity,
        pickupState: payload.pickupState,
        pickupPostalCode: payload.pickupPostalCode,
        deliveryAddress: payload.deliveryAddress,
        deliveryCity: payload.deliveryCity,
        deliveryState: payload.deliveryState,
        deliveryPostalCode: payload.deliveryPostalCode,
        receiverName: payload.receiverName,
        receiverPhone: payload.receiverPhone,
        packageType: payload.packageType,
        packageWeightKg: payload.packageWeightKg,
        ...dimensions,
        vehiclePreference: payload.vehiclePreference,
        isFragile: payload.isFragile,
        deliveryNotes: payload.deliveryNotes,
        pickupDateTime: new Date(payload.pickupDateTime),
        estimatedDistanceKm: estimate.estimatedDistanceKm,
        estimatedDurationMinutes: estimate.estimatedDurationMinutes,
        estimatedPrice: estimate.breakdown.totalAmount,
        shipmentStatus: 'pending',
        paymentStatus: 'unpaid',
      },
      connection,
    );

    await connection.commit();

    return {
      shipment,
      priceEstimate: estimate,
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const getShipmentSummary = async (userId, shipmentId) => {
  const customer = await getActiveCustomer(userId);
  const shipment = await shipmentModel.findByIdForCustomer({
    shipmentId,
    customerId: customer.id,
  });

  if (!shipment) {
    throw new AppError('Shipment was not found', 404);
  }

  const priceEstimate = await calculatePriceEstimate({
    categoryId: shipment.categoryId,
    packageWeightKg: shipment.packageWeightKg,
    estimatedDistanceKm: shipment.estimatedDistanceKm,
    isFragile: shipment.isFragile,
  });
  const payment = await paymentModel.findPaidByShipmentId(shipment.id);

  return {
    shipment,
    priceEstimate,
    payment,
    nextAction:
      shipment.paymentStatus === 'paid' ? 'track_shipment' : 'place_order',
  };
};

const placeOrderAfterMockPayment = async (userId, shipmentId, payload) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();
    const customer = await getActiveCustomer(userId, connection);
    const shipment = await shipmentModel.findByIdForCustomer(
      {
        shipmentId,
        customerId: customer.id,
      },
      connection,
    );

    if (!shipment) {
      throw new AppError('Shipment was not found', 404);
    }

    if (shipment.paymentStatus === 'paid') {
      throw new AppError('Shipment order is already paid', 409);
    }

    const priceEstimate = await calculatePriceEstimate(
      {
        categoryId: shipment.categoryId,
        packageWeightKg: shipment.packageWeightKg,
        estimatedDistanceKm: shipment.estimatedDistanceKm,
        isFragile: shipment.isFragile,
      },
      connection,
    );
    const payment = await paymentModel.createPayment(
      {
        paymentCode: generateCode('PAY'),
        shipmentId: shipment.id,
        customerId: customer.id,
        paymentMethod: payload.paymentMethod,
        paymentStatus: 'paid',
        subtotalAmount: priceEstimate.breakdown.subtotalAmount,
        discountAmount: priceEstimate.breakdown.discountAmount,
        taxAmount: priceEstimate.breakdown.taxAmount,
        feeAmount: priceEstimate.breakdown.feeAmount,
        totalAmount: priceEstimate.breakdown.totalAmount,
        transactionReference: generateCode('MOCK'),
        metadata: {
          provider: 'mock',
          termsAccepted: payload.acceptTerms === true,
        },
      },
      connection,
    );
    const updatedShipment = await shipmentModel.updatePaymentStatus(
      {
        shipmentId: shipment.id,
        customerId: customer.id,
        paymentStatus: 'paid',
        shipmentStatus: 'pending',
      },
      connection,
    );

    await customerModel.incrementTotalShipments(customer.id, connection);
    await notificationService.notifyBookingCreated(
      {
        customerUserId: userId,
        shipment: updatedShipment,
      },
      connection,
    );
    await connection.commit();

    return {
      bookingId: updatedShipment.shipmentCode,
      shipment: updatedShipment,
      payment,
      status: 'pending',
      message: 'Mock payment captured. Shipment is pending admin approval.',
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

module.exports = {
  calculateCustomerPriceEstimate,
  calculatePriceEstimate,
  createShipmentRequest,
  getShipmentSummary,
  placeOrderAfterMockPayment,
};
