const PDFDocument = require('pdfkit');

const currency = (value) => `INR ${Number(value).toFixed(2)}`;

const collectPdfBuffer = (doc) => {
  return new Promise((resolve, reject) => {
    const chunks = [];

    doc.on('data', (chunk) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
  });
};

const drawKeyValue = (doc, label, value, x, y) => {
  doc.font('Helvetica-Bold').fontSize(9).fillColor('#5B6472').text(label, x, y);
  doc.font('Helvetica').fontSize(10).fillColor('#111827').text(value || '-', x, y + 14);
};

const generateInvoicePdf = async ({ invoice, shipment, payment }) => {
  const doc = new PDFDocument({ size: 'A4', margin: 48 });
  const pdfReady = collectPdfBuffer(doc);

  doc.fillColor('#0B1F3A').font('Helvetica-Bold').fontSize(24).text('CargoConnect');
  doc.fillColor('#5B6472').font('Helvetica').fontSize(10).text('Reliable logistics and transport services');
  doc.moveDown(1.5);

  doc.fillColor('#111827').font('Helvetica-Bold').fontSize(18).text('Tax Invoice');
  doc.moveDown(0.5);
  doc.font('Helvetica').fontSize(10).text(`Invoice Number: ${invoice.invoiceNumber}`);
  doc.text(`Issued At: ${new Date(invoice.issuedAt).toLocaleString('en-IN')}`);
  doc.text(`Payment Status: ${invoice.paymentStatus.toUpperCase()}`);
  doc.moveDown(1.5);

  const startY = doc.y;
  drawKeyValue(doc, 'Bill To', invoice.billingName, 48, startY);
  drawKeyValue(doc, 'Email', invoice.billingEmail, 48, startY + 42);
  drawKeyValue(doc, 'Phone', invoice.billingPhone, 48, startY + 84);
  drawKeyValue(doc, 'Shipment', shipment.shipmentCode, 320, startY);
  drawKeyValue(doc, 'Pickup', shipment.pickupAddress, 320, startY + 42);
  drawKeyValue(doc, 'Delivery', shipment.deliveryAddress, 320, startY + 84);
  doc.y = startY + 140;

  doc.moveTo(48, doc.y).lineTo(545, doc.y).strokeColor('#E5E7EB').stroke();
  doc.moveDown(1);
  doc.fillColor('#111827').font('Helvetica-Bold').fontSize(12).text('Shipment Details');
  doc.moveDown(0.5);
  doc.font('Helvetica').fontSize(10);
  doc.text(`Package: ${shipment.packageType}`);
  doc.text(`Weight: ${shipment.packageWeightKg} kg`);
  doc.text(`Vehicle Preference: ${shipment.vehiclePreference || shipment.categoryName}`);
  doc.text(`Receiver: ${shipment.receiverName} (${shipment.receiverPhone})`);
  doc.moveDown(1);

  const tableTop = doc.y + 8;
  doc.font('Helvetica-Bold').text('Charge', 48, tableTop);
  doc.text('Amount', 450, tableTop, { align: 'right' });
  doc.moveTo(48, tableTop + 18).lineTo(545, tableTop + 18).strokeColor('#E5E7EB').stroke();

  const rows = [
    ['Subtotal', invoice.subtotalAmount],
    ['Discount', -invoice.discountAmount],
    ['Taxes', invoice.taxAmount],
    ['Total', invoice.totalAmount],
  ];

  let y = tableTop + 32;
  rows.forEach(([label, amount], index) => {
    const isTotal = index === rows.length - 1;
    doc.font(isTotal ? 'Helvetica-Bold' : 'Helvetica').fontSize(isTotal ? 12 : 10);
    doc.text(label, 48, y);
    doc.text(currency(amount), 400, y, { align: 'right', width: 145 });
    y += isTotal ? 24 : 20;
  });

  doc.moveDown(2);
  doc.font('Helvetica').fontSize(9).fillColor('#5B6472');
  doc.text(`Payment Method: ${payment.paymentMethod}`);
  doc.text(`Transaction Reference: ${payment.transactionReference}`);
  doc.moveDown(2);
  doc.text('This invoice was generated locally by CargoConnect for mock payment testing.');

  doc.end();
  return pdfReady;
};

module.exports = {
  generateInvoicePdf,
};
