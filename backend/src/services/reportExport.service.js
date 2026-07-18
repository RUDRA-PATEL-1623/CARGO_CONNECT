const PDFDocument = require('pdfkit');

const collectPdfBuffer = (doc) => {
  return new Promise((resolve, reject) => {
    const chunks = [];

    doc.on('data', (chunk) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
  });
};

const formatValue = (value) => {
  if (value === null || value === undefined) {
    return '';
  }

  if (value instanceof Date) {
    return value.toISOString();
  }

  if (typeof value === 'boolean') {
    return value ? 'Yes' : 'No';
  }

  return String(value);
};

const escapeCsvValue = (value) => {
  const formatted = formatValue(value);

  if (/[",\r\n]/.test(formatted)) {
    return `"${formatted.replace(/"/g, '""')}"`;
  }

  return formatted;
};

const buildCsv = ({ columns, rows }) => {
  const header = columns.map((column) => escapeCsvValue(column.label)).join(',');
  const body = rows.map((row) => (
    columns.map((column) => escapeCsvValue(column.value(row))).join(',')
  ));

  return Buffer.from([header, ...body].join('\r\n'), 'utf8');
};

const drawMetadata = (doc, filters = {}) => {
  const entries = Object.entries(filters)
    .filter(([, value]) => value !== null && value !== undefined && value !== '')
    .slice(0, 8);

  if (entries.length === 0) {
    doc.fillColor('#5B6472').font('Helvetica').fontSize(9).text('Filters: none');
    return;
  }

  doc.fillColor('#5B6472').font('Helvetica').fontSize(9);
  doc.text(`Filters: ${entries.map(([key, value]) => `${key}=${value}`).join(', ')}`);
};

const drawSummary = (doc, summary = {}) => {
  const statusRows = summary.statusWise || [];
  const categoryRows = summary.categoryWise || [];

  doc.moveDown(1);
  doc.fillColor('#111827').font('Helvetica-Bold').fontSize(12).text('Summary');
  doc.moveDown(0.3);
  doc.fillColor('#5B6472').font('Helvetica').fontSize(9);
  doc.text(`Date groups: ${(summary.dateWise || []).length}`);
  doc.text(`Status groups: ${statusRows.length}`);
  doc.text(`Category groups: ${categoryRows.length}`);

  if (statusRows[0]) {
    const statusLabel = statusRows[0].status || statusRows[0].paymentStatus || 'status';
    const statusCount =
      statusRows[0].shipmentCount
      || statusRows[0].paymentCount
      || statusRows[0].invoiceCount
      || statusRows[0].driverCount
      || statusRows[0].vehicleCount
      || 0;
    doc.text(`Top status: ${statusLabel} (${statusCount})`);
  }

  if (categoryRows[0]) {
    const categoryCount =
      categoryRows[0].shipmentCount
      || categoryRows[0].paymentCount
      || categoryRows[0].invoiceCount
      || categoryRows[0].assignmentCount
      || 0;
    doc.text(`Top category: ${categoryRows[0].categoryName} (${categoryCount})`);
  }
};

const ensurePageSpace = (doc, rowHeight = 20) => {
  if (doc.y + rowHeight > doc.page.height - doc.page.margins.bottom) {
    doc.addPage();
  }
};

const generatePdf = async ({ title, filters, summary, columns, rows }) => {
  const doc = new PDFDocument({
    size: 'A4',
    margin: 42,
  });
  const pdfReady = collectPdfBuffer(doc);
  const tableColumns = columns.slice(0, 5);
  const pageWidth = doc.page.width - doc.page.margins.left - doc.page.margins.right;
  const columnWidth = pageWidth / tableColumns.length;

  doc.fillColor('#0B1F3A').font('Helvetica-Bold').fontSize(22).text('CargoConnect');
  doc.fillColor('#5B6472').font('Helvetica').fontSize(10).text('Operational report export');
  doc.moveDown(1);
  doc.fillColor('#111827').font('Helvetica-Bold').fontSize(16).text(title);
  doc.fillColor('#5B6472').font('Helvetica').fontSize(9).text(`Generated: ${new Date().toISOString()}`);
  drawMetadata(doc, filters);
  drawSummary(doc, summary);
  doc.moveDown(1);

  doc.fillColor('#111827').font('Helvetica-Bold').fontSize(10).text('Rows');
  doc.moveDown(0.5);

  let startY = doc.y;
  tableColumns.forEach((column, index) => {
    doc
      .fillColor('#111827')
      .font('Helvetica-Bold')
      .fontSize(8)
      .text(column.label, doc.page.margins.left + index * columnWidth, startY, {
        width: columnWidth - 8,
      });
  });
  doc.moveTo(doc.page.margins.left, startY + 14)
    .lineTo(doc.page.width - doc.page.margins.right, startY + 14)
    .strokeColor('#E5E7EB')
    .stroke();
  doc.y = startY + 22;

  rows.slice(0, 200).forEach((row) => {
    ensurePageSpace(doc, 26);
    startY = doc.y;
    tableColumns.forEach((column, index) => {
      doc
        .fillColor('#374151')
        .font('Helvetica')
        .fontSize(8)
        .text(formatValue(column.value(row)), doc.page.margins.left + index * columnWidth, startY, {
          width: columnWidth - 8,
          height: 22,
          ellipsis: true,
        });
    });
    doc.y = startY + 26;
  });

  if (rows.length > 200) {
    ensurePageSpace(doc, 18);
    doc
      .fillColor('#5B6472')
      .font('Helvetica')
      .fontSize(9)
      .text(`PDF preview includes first 200 rows of ${rows.length}. Use CSV for the full row export.`);
  }

  doc.end();
  return pdfReady;
};

module.exports = {
  buildCsv,
  generatePdf,
};
