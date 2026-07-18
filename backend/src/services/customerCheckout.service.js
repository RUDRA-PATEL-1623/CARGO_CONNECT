const { getPool } = require('../config/database');
const customerModel = require('../models/customer.model');
const invoiceModel = require('../models/invoice.model');
const paymentModel = require('../models/payment.model');
const shipmentModel = require('../models/shipment.model');
const userModel = require('../models/user.model');
const customerShipmentService = require('./customerShipment.service');
const invoicePdfService = require('./invoicePdf.service');
const notificationService = require('./notification.service');
const AppError = require('../utils/appError');

const generateCode = (prefix) => {
  const datePart = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const randomPart = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
  return `${prefix}-${datePart}-${Date.now().toString().slice(-6)}${randomPart}`;
};

const buildBillingAddress = (customer) => {
  return [
    customer.addressLine1,
    customer.addressLine2,
    customer.city,
    customer.state,
    customer.postalCode,
    customer.country,
  ]
    .filter(Boolean)
    .join(', ');
};

const withInvoiceLinks = (invoice) => {
  if (!invoice) {
    return null;
  }

  return {
    ...invoice,
    downloadUrl: `/api/v1/customer/invoices/${invoice.id}/download`,
  };
};

const getActiveCustomer = async (userId, connection = null) => {
  const customer = await customerModel.findByUserId(userId, connection);

  if (!customer || customer.accountStatus !== 'active') {
    throw new AppError('Active customer profile is required', 403);
  }

  return customer;
};

const getCustomerShipment = async ({ userId, shipmentId, connection = null }) => {
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

  return {
    customer,
    shipment,
  };
};

const buildCheckout = async (userId, shipmentId) => {
  const { shipment } = await getCustomerShipment({ userId, shipmentId });
  const priceEstimate = await customerShipmentService.calculatePriceEstimate({
    categoryId: shipment.categoryId,
    packageWeightKg: shipment.packageWeightKg,
    estimatedDistanceKm: shipment.estimatedDistanceKm,
    isFragile: shipment.isFragile,
  });
  const payment = await paymentModel.findPaidByShipmentId(shipment.id);
  const invoice = await invoiceModel.findByShipmentIdForCustomer({
    shipmentId: shipment.id,
    customerId: shipment.customerId,
  });

  return {
    shipment,
    priceEstimate,
    paymentMethods: ['upi', 'card', 'cash', 'wallet'],
    termsRequired: true,
    payment,
    invoice: withInvoiceLinks(invoice),
  };
};

const createInvoiceForPayment = async (
  { customer, user, shipment, payment, priceEstimate },
  connection,
) => {
  const existingInvoice = await invoiceModel.findByShipmentIdForCustomer(
    {
      shipmentId: shipment.id,
      customerId: customer.id,
    },
    connection,
  );

  if (existingInvoice) {
    return existingInvoice;
  }

  const invoice = await invoiceModel.createInvoice(
    {
      invoiceNumber: generateCode('INV'),
      shipmentId: shipment.id,
      paymentId: payment.id,
      customerId: customer.id,
      invoiceStatus: 'generated',
      paymentStatus: payment.paymentStatus,
      billingName: user.name,
      billingEmail: user.email,
      billingPhone: user.phone,
      billingAddress: buildBillingAddress(customer),
      subtotalAmount: priceEstimate.breakdown.subtotalAmount,
      discountAmount: priceEstimate.breakdown.discountAmount,
      taxAmount: priceEstimate.breakdown.taxAmount,
      totalAmount: priceEstimate.breakdown.totalAmount,
      pdfUrl: null,
    },
    connection,
  );

  return withInvoiceLinks(invoice);
};

const confirmMockPayment = async (userId, shipmentId, payload) => {
  const pool = getPool();
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const { customer, shipment } = await getCustomerShipment({
      userId,
      shipmentId,
      connection,
    });
    const user = await userModel.findById(userId, { connection });

    if (shipment.paymentStatus === 'paid') {
      throw new AppError('Shipment order is already paid', 409);
    }

    const priceEstimate = await customerShipmentService.calculatePriceEstimate(
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
          couponCode: payload.couponCode || null,
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
    const invoice = await createInvoiceForPayment(
      {
        customer,
        user,
        shipment: updatedShipment,
        payment,
        priceEstimate,
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
      invoice,
      status: 'pending',
      message: 'Mock payment captured and invoice generated.',
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

const getInvoicePreview = async (userId, invoiceId) => {
  const customer = await getActiveCustomer(userId);
  const invoice = await invoiceModel.findByIdForCustomer({
    invoiceId,
    customerId: customer.id,
  });

  if (!invoice) {
    throw new AppError('Invoice was not found', 404);
  }

  const shipment = await shipmentModel.findByIdForCustomer({
    shipmentId: invoice.shipmentId,
    customerId: customer.id,
  });
  const payment = invoice.paymentId
    ? await paymentModel.findById(invoice.paymentId)
    : null;

  return {
    company: {
      name: 'CargoConnect',
      email: 'billing@cargoconnect.local',
      address: 'CargoConnect Logistics HQ, India',
    },
    invoice: withInvoiceLinks(invoice),
    shipment,
    payment,
  };
};

const generateInvoicePdf = async (userId, invoiceId) => {
  const preview = await getInvoicePreview(userId, invoiceId);

  if (!preview.payment) {
    throw new AppError('Paid payment record is required for invoice PDF', 422);
  }

  const buffer = await invoicePdfService.generateInvoicePdf(preview);

  return {
    buffer,
    filename: `${preview.invoice.invoiceNumber}.pdf`,
  };
};

module.exports = {
  buildCheckout,
  confirmMockPayment,
  createInvoiceForPayment,
  generateInvoicePdf,
  getInvoicePreview,
};
