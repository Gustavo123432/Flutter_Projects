/**
 * SIBS Gateway V2 Webhook Handler
 * 
 * This file implements a complete webhook handler for SIBS Gateway V2 payment notifications.
 * It includes functionality to receive, decrypt, process, and acknowledge webhook notifications.
 */

const express = require('express');
const bodyParser = require('body-parser');
const crypto = require('crypto');
const dotenv = require('dotenv');
const mysql = require('mysql2/promise');

// Load environment variables
dotenv.config();

// Create MySQL connection pool
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'appbar',
  password: process.env.DB_PASSWORD || 'apiappbar2024',
  database: process.env.DB_NAME || 'sibs_mbway',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

const app = express();
const PORT = process.env.PORT || 5816;
const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY || 'Ch8BSUJBU/Rip9NrfxhcZU5Ebwbmr/1odtuQzGJRm9Y=';
const AUTHORIZATION_API = process.env.AUTHORIZATION_API || '0276b80f950fb446c6addaccd121abfbbb.eyJlIjoiMjA1ODQyODEyNTE1MCIsInJvbGVzIjoiU1BHX01BTkFHRVIiLCJ0b2tlbkFwcERhdGEiOiJ7XCJtY1wiOlwiNTA2MzUwXCIsXCJ0Y1wiOlwiODIxNDRcIn0iLCJpIjoiMTc0Mjg5ODkyNTE1MCIsImlzIjoiaHR0cHM6Ly9xbHkuc2l0ZTEuc3NvLnN5cy5zaWJzLnB0L2F1dGgvcmVhbG1zL1FMWS5NRVJDSC5QT1JUMSIsInR5cCI6IkJlYXJlciIsImlkIjoiS3ExRUVzM2dLQzJmODQzYjljNGZlNjQ1MGJiZGRhMDU0ZTljZWRhZmFkIn0=.362668a74fc23ae86d72e66caccb82208f60f1fe84edbdb0085b650ca4bdfafdf41e237afc608eeb75bbaff687c67bf6acec00d53116f3564d878d648b3c3795';
const CLIENT_ID = process.env.CLIENT_ID || '28d23dd7-a494-4d0d-97d5-dc6cd9f85576';

// Add endpoint configurations
const BASE_URL = process.env.BASE_URL || '/api';
const WEBHOOK_PATH = process.env.WEBHOOK_PATH || '/webhook';
const HEALTH_PATH = process.env.HEALTH_PATH || '/health';
const TEST_PATH = process.env.TEST_PATH || '/webhook/test';
const STATUS_PATH = process.env.STATUS_PATH || '/status';

// Parse JSON request body with increased limit
app.use(bodyParser.json({ limit: '10mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '10mb' }));

// Parse raw body for encrypted data
app.use(express.raw({
  type: 'text/plain',
  limit: '10mb'
}));

// Add CORS headers
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  
  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

// Add request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  console.log('Headers:', JSON.stringify(req.headers));
  console.log('Body:', JSON.stringify(req.body));
  next();
});

// Create router for API endpoints
const router = express.Router();

// GET handler for webhook endpoint - provides information
router.get(WEBHOOK_PATH, (req, res) => {
  res.status(405).json({
    statusCode: "405",
    statusMsg: "Method Not Allowed",
    message: "This webhook endpoint only accepts POST requests",
    documentation: {
      description: "SIBS Gateway V2 Webhook Handler",
      acceptedMethods: ["POST"],
      contentType: "application/json",
      endpoints: {
        webhook: `https://api.appbar.epvc.pt${BASE_URL}${WEBHOOK_PATH}`,
        health: `https://api.appbar.epvc.pt${BASE_URL}${HEALTH_PATH}`,
        test: `https://api.appbar.epvc.pt${BASE_URL}${TEST_PATH}`
      },
      example: {
        method: "POST",
        contentType: "application/json",
        body: {
          returnStatus: {
            statusMsg: "Success",
            statusCode: "000"
          },
          paymentStatus: "Success",
          paymentMethod: "MBWAY",
          transactionID: "test123",
          notificationID: "test-123",
          amount: {
            currency: "EUR",
            value: 10.00
          }
        }
      }
    }
  });
});

/**
 * Decrypt webhook payload using AES-256-GCM
 * @param {string} encryptedData - The encrypted webhook data (Base64 encoded)
 * @param {string} key - Encryption key configured in SIBS Gateway V2 Backoffice
 * @param {string} iv - Initialization vector (Base64 encoded)
 * @param {string} authTag - Authentication tag (Base64 encoded)
 * @returns {Object} - Decrypted webhook data as JSON object
 */
function decryptWebhookGCM(encryptedData, key, iv, authTag) {
  try {
    // Convert Base64 inputs to Buffers
    const keyBuffer = Buffer.from(key, 'base64');
    const ivBuffer = Buffer.from(iv, 'base64');
    const authTagBuffer = Buffer.from(authTag, 'base64');
    const encryptedBuffer = Buffer.from(encryptedData, 'base64');

    // Create decipher with AES-256-GCM
    const decipher = crypto.createDecipheriv('aes-256-gcm', keyBuffer, ivBuffer);
    decipher.setAuthTag(authTagBuffer);

    // Decrypt the data
    let decrypted = decipher.update(encryptedBuffer);
    decrypted = Buffer.concat([decrypted, decipher.final()]);

    // Parse the decrypted data as JSON
    return JSON.parse(decrypted.toString('utf8'));
  } catch (error) {
    console.error('GCM Decryption error:', error);
    throw new Error('Failed to decrypt webhook payload (GCM)');
  }
}

// Webhook POST endpoint
router.post(WEBHOOK_PATH, async (req, res) => {
  try {
    console.log('Webhook received at:', new Date().toISOString());
    console.log('Raw request body:', req.body.toString());

    let webhookData;
    
    // Check for GCM encryption headers
    if (req.headers['x-initialization-vector'] && req.headers['x-authentication-tag']) {
      try {
        // Get the raw body as text
        const rawBody = req.body.toString();
        
        // Decrypt using GCM mode
        webhookData = decryptWebhookGCM(
          rawBody,
          ENCRYPTION_KEY,
          req.headers['x-initialization-vector'],
          req.headers['x-authentication-tag']
        );
        console.log('Decrypted GCM webhook data:', JSON.stringify(webhookData));
      } catch (decryptError) {
        console.error('GCM Decryption failed:', decryptError);
        throw new Error('Failed to decrypt webhook data');
      }
    }
    // Check if the data is encrypted in legacy format
    else if (req.body.encryptedData) {
      try {
        // Decrypt using legacy CBC mode
        webhookData = decryptWebhook(req.body.encryptedData, ENCRYPTION_KEY);
        console.log('Decrypted legacy webhook data:', JSON.stringify(webhookData));
      } catch (decryptError) {
        console.error('Legacy decryption failed:', decryptError);
        // If decryption fails, check if the body has the required webhook structure
        if (req.body.returnStatus && req.body.paymentMethod && req.body.notificationID) {
          console.log('Using raw data as fallback');
          webhookData = req.body;
        } else {
          throw new Error('Invalid webhook data format');
        }
      }
    } else {
      // Check if the raw body has the required webhook structure
      if (req.body.returnStatus && req.body.paymentMethod && req.body.notificationID) {
        console.log('Processing unencrypted webhook data');
        webhookData = req.body;
      } else {
        throw new Error('Invalid webhook data format');
      }
    }

    // Validate webhook data structure
    if (!validateWebhookData(webhookData)) {
      throw new Error('Invalid webhook data structure');
    }

    // Process the webhook data based on payment method and status
    await processWebhook(webhookData);
    
    // Send acknowledgment response to prevent retries
    const response = {
      statusCode: "200",
      statusMsg: "Success",
      notificationID: webhookData.notificationID
    };

    console.log('Sending response:', JSON.stringify(response));
    res.status(200).json(response);
  } catch (error) {
    console.error('Error processing webhook:', error);
    
    // Send error response
    let notificationID = '';
    try {
      notificationID = req.body.notificationID || 
                      (req.body.encryptedData ? 'encrypted' : '');
    } catch (e) {
      // Ignore errors in error handling
    }
    
    const errorResponse = {
      statusCode: "500",
      statusMsg: "Error",
      notificationID: notificationID
    };

    console.error('Sending error response:', JSON.stringify(errorResponse));
    res.status(500).json(errorResponse);
  }
});

/**
 * Validate webhook data structure
 * @param {Object} data - The webhook data to validate
 * @returns {boolean} - True if valid, false otherwise
 */
function validateWebhookData(data) {
  // Check required fields according to SIBS documentation
  if (!data || typeof data !== 'object') return false;
  
  // Check basic required fields
  const requiredFields = [
    'returnStatus',
    'paymentStatus',
    'paymentMethod',
    'transactionID',
    'notificationID'
  ];
  
  for (const field of requiredFields) {
    if (!data[field]) return false;
  }
  
  // Check returnStatus structure
  if (!data.returnStatus.statusMsg || !data.returnStatus.statusCode) {
    return false;
  }
  
  // Validate paymentMethod
  const validPaymentMethods = [
    'MBWAY', 'CARD', 'REFERENCE', 'TOKEN', 
    'STATIC_QRCODE', 'MANDATE', 'XPAY'
  ];
  if (!validPaymentMethods.includes(data.paymentMethod)) {
    return false;
  }
  
  // Validate paymentStatus
  const validPaymentStatuses = [
    'Success', 'Partial', 'Declined', 'InProcessing', 
    'Pending', 'Timeout', 'Error'
  ];
  if (!validPaymentStatuses.includes(data.paymentStatus)) {
    return false;
  }
  
  return true;
}

/**
 * Process the webhook data based on payment method and status
 * @param {Object} webhookData - The webhook notification data
 */
async function processWebhook(webhookData) {
  const { paymentMethod, paymentStatus, paymentType, transactionID } = webhookData;
  
  console.log(`Processing ${paymentMethod} ${paymentType} with status ${paymentStatus}`);
  
  // Handle different payment methods and statuses
  switch (paymentMethod) {
    case 'CARD':
      await handleCardPayment(webhookData);
      break;
    case 'MBWAY':
      await handleMBWayPayment(webhookData);
      break;
    case 'REFERENCE':
      await handleReferencePayment(webhookData);
      break;
    case 'TOKEN':
      await handleTokenPayment(webhookData);
      break;
    case 'STATIC_QRCODE':
      await handleQRCodePayment(webhookData);
      break;
    case 'MANDATE':
      await handleMandatePayment(webhookData);
      break;
    default:
      console.log(`Unknown payment method: ${paymentMethod}`);
  }
  
  // Store transaction details in database
  await saveTransaction(transactionID, webhookData);
}

/**
 * Handle card payment webhooks
 * @param {Object} webhookData - The webhook notification data
 */
async function handleCardPayment(webhookData) {
  // Implementation for card payments
  console.log('Processing card payment:', webhookData.transactionID);
  
  // Handle different payment types for card payments
  switch (webhookData.paymentType) {
    case 'PURS': // Purchase
      // Update order status to paid
      console.log('Card purchase payment');
      break;
    case 'AUTH': // Authorization
      // Handle authorization
      console.log('Card authorization');
      break;
    case 'MITR': // Merchant Initiated Transaction
      // Handle merchant initiated transaction
      console.log('Merchant Initiated Transaction');
      break;
    // Add other payment types as needed
  }
  
  // Handle Merchant Initiated Transactions if present
  if (webhookData.merchantInitiatedTransaction) {
    const { type, amountQualifier } = webhookData.merchantInitiatedTransaction;
    console.log(`Processing MIT with type ${type} and amount qualifier ${amountQualifier}`);
    
    // Handle recurring payments
    if (type === 'RCRR') {
      // Handle recurring payment
      console.log('Recurring payment');
    }
    
    // Handle unscheduled credential on file
    if (type === 'UCOF') {
      // Handle unscheduled credential on file
      console.log('Unscheduled credential on file payment');
    }
  }
}

/**
 * Handle MB WAY payment webhooks
 * @param {Object} webhookData - The webhook notification data
 */
async function handleMBWayPayment(webhookData) {
  // Implementation for MB WAY payments
  console.log('Processing MB WAY payment:', webhookData.transactionID);
  
  // Check if this is an Authorized Payment
  if (webhookData.mbwayMandate) {
    // Handle MB WAY mandate operations
    const { mandateAction, mandateActionStatus } = webhookData.mbwayMandate;
    
    if (mandateAction === 'CRTN' && mandateActionStatus === 'SCCS') {
      // Successfully created MB WAY Authorized Payment
      console.log('MB WAY Authorized Payment created successfully');
    } else if (mandateAction === 'CNCL') {
      // Canceled MB WAY Authorized Payment
      console.log('MB WAY Authorized Payment canceled');
    } else if (mandateAction === 'SSPN') {
      // Suspended MB WAY Authorized Payment
      console.log('MB WAY Authorized Payment suspended');
    } else if (mandateAction === 'RCTV') {
      // Reactivated MB WAY Authorized Payment
      console.log('MB WAY Authorized Payment reactivated');
    } else if (mandateAction === 'LMUP') {
      // Updated MB WAY Authorized Payment limits
      console.log('MB WAY Authorized Payment limits updated');
    }
  } else if (webhookData.paymentType === 'CSHT') {
    // Handle Cashout
    console.log('Processing MB WAY Cashout');
    
    if (webhookData.paymentStatus === 'Success') {
      console.log(`Successful cashout to ${webhookData.clientIBAN || 'N/A'}`);
    } else {
      console.log(`Failed cashout with status ${webhookData.paymentStatus}`);
    }
  } else {
    // Regular MB WAY payment
    console.log('Processing regular MB WAY payment');
    
    if (webhookData.token && webhookData.token.value) {
      console.log(`MB WAY alias: ${webhookData.token.value}`);
    }
  }
}

/**
 * Handle reference payment webhooks
 * @param {Object} webhookData - The webhook notification data
 */
async function handleReferencePayment(webhookData) {
  // Implementation for reference payments
  console.log('Processing reference payment:', webhookData.transactionID);
  
  // Check if this is a reference generation or payment
  if (webhookData.paymentReference) {
    const { reference, entity, status, expiryDate } = webhookData.paymentReference;
    
    console.log(`Reference: ${entity}/${reference}, Status: ${status}, Expires: ${expiryDate || 'N/A'}`);
    
    if (status === 'UNPAID') {
      // New reference generated
      console.log('New payment reference generated');
      
      // Store reference details
      const { value, currency } = webhookData.paymentReference.amount;
      console.log(`Amount: ${value} ${currency}`);
    } else if (status === 'PAID') {
      // Reference payment successful
      console.log('Reference payment successful');
    }
  } else if (webhookData.paymentStatus === 'Success') {
    // Reference payment successful
    console.log('Reference payment successful');
  }
}

/**
 * Handle token payment webhooks
 * @param {Object} webhookData - The webhook notification data
 */
async function handleTokenPayment(webhookData) {
  // Implementation for token payments
  console.log('Processing token payment:', webhookData.transactionID);
  
  if (webhookData.token) {
    const { tokenType, value } = webhookData.token;
    console.log(`Token type: ${tokenType}, value: ${value}`);
    
    if (webhookData.token.maskedPAN) {
      console.log(`Masked PAN: ${webhookData.token.maskedPAN}`);
    }
  }
  
  if (webhookData.paymentType === 'AUTH') {
    // Token generation
    console.log('Token generation');
  } else if (webhookData.paymentType === 'PURS') {
    // Token payment
    console.log('Token payment');
  }
}

/**
 * Handle QR code payment webhooks
 * @param {Object} webhookData - The webhook notification data
 */
async function handleQRCodePayment(webhookData) {
  // Implementation for QR code payments
  console.log('Processing QR code payment:', webhookData.transactionID);
  
  if (webhookData.financialOperation && webhookData.financialOperation.product) {
    const product = webhookData.financialOperation.product;
    
    console.log(`QR Code ID: ${product.staticQRCodeId}`);
    console.log(`Product: ${product.productName}, Quantity: ${product.productQuantity}, Amount: ${product.productAmount}`);
    
    if (product.expeditionAmount) {
      console.log(`Expedition amount: ${product.expeditionAmount}`);
    }
  }
  
  // Handle billing information if present
  if (webhookData.financialOperation && webhookData.financialOperation.billingInfo) {
    const billing = webhookData.financialOperation.billingInfo;
    console.log(`Billing TIN: ${billing.billingTIN}`);
    console.log(`Billing Address: ${billing.billingAddressLine1}, ${billing.billingAddressCity}`);
  }
}

/**
 * Handle mandate payment webhooks
 * @param {Object} webhookData - The webhook notification data
 */
async function handleMandatePayment(webhookData) {
  // Implementation for mandate payments
  console.log('Processing mandate payment:', webhookData.transactionID);
  
  // Check payment type
  if (webhookData.paymentType === 'CAUT') {
    // Cancel authorization
    console.log('Mandate cancellation');
  }
}

/**
 * Save transaction data to database
 * @param {string} transactionID - The transaction ID
 * @param {Object} data - The transaction data
 */
async function saveTransaction(transactionID, data) {
  try {
    const connection = await pool.getConnection();
    
    try {
      // Convert ISO datetime to MySQL format
      let transactionDateTime = data.transactionDateTime || new Date().toISOString();
      // Remove timezone offset and convert to MySQL datetime format
      transactionDateTime = transactionDateTime.replace(/T/, ' ').replace(/\.\d+Z$/, '').replace(/([+-]\d{2}):(\d{2})$/, '');
      
      const transaction = {
        transaction_id: transactionID,
        transaction_signature: data.transactionSignature || null,
        payment_method: data.paymentMethod,
        payment_type: data.paymentType,
        payment_status: data.paymentStatus,
        transaction_datetime: transactionDateTime,
        amount_value: data.amount?.value || null,
        amount_currency: data.amount?.currency || null,
        merchant_transaction_id: data.merchant?.transactionId || null,
        merchant_terminal_id: data.merchant?.terminalId || null,
        merchant_name: data.merchant?.merchantName || null,
        merchant_in_app: data.merchant?.inApp || 'false',
        notification_id: data.notificationID
      };

      // Insert or update transaction
      await connection.query(
        `INSERT INTO transactions 
        (transaction_id, transaction_signature, payment_method, payment_type, payment_status, 
         transaction_datetime, amount_value, amount_currency, merchant_transaction_id, 
         merchant_terminal_id, merchant_name, merchant_in_app, notification_id) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE 
        payment_method = VALUES(payment_method),
        payment_type = VALUES(payment_type),
        payment_status = VALUES(payment_status),
        transaction_datetime = VALUES(transaction_datetime),
        amount_value = VALUES(amount_value),
        amount_currency = VALUES(amount_currency),
        merchant_transaction_id = VALUES(merchant_transaction_id),
        merchant_terminal_id = VALUES(merchant_terminal_id),
        merchant_name = VALUES(merchant_name),
        merchant_in_app = VALUES(merchant_in_app),
        notification_id = VALUES(notification_id)`,
        [
          transaction.transaction_id,
          transaction.transaction_signature,
          transaction.payment_method,
          transaction.payment_type,
          transaction.payment_status,
          transaction.transaction_datetime,
          transaction.amount_value,
          transaction.amount_currency,
          transaction.merchant_transaction_id,
          transaction.merchant_terminal_id,
          transaction.merchant_name,
          transaction.merchant_in_app,
          transaction.notification_id
        ]
      );

      console.log(`Transaction ${transactionID} saved to database`);
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error(`Error saving transaction ${transactionID}:`, error);
    throw error;
  }
}

/**
 * Decrypt webhook payload using AES-256
 * @param {string} encryptedData - The encrypted webhook data (Base64 encoded)
 * @param {string} key - Encryption key configured in SIBS Gateway V2 Backoffice
 * @returns {Object} - Decrypted webhook data as JSON object
 */
function decryptWebhook(encryptedData, key) {
  if (typeof encryptedData !== 'string') {
    throw new Error('Encrypted data must be a string');
  }

  try {
    // Convert Base64 key to Buffer
    const keyBuffer = Buffer.from(key, 'base64');
    
    // The first 16 bytes of the encrypted data is the IV
    const encrypted = Buffer.from(encryptedData, 'base64');
    const iv = encrypted.slice(0, 16);
    const data = encrypted.slice(16);
    
    // Create decipher with key and iv
    const decipher = crypto.createDecipheriv('aes-256-cbc', keyBuffer, iv);
    
    // Decrypt the data
    let decrypted = decipher.update(data);
    decrypted = Buffer.concat([decrypted, decipher.final()]);
    
    // Parse the decrypted data as JSON
    return JSON.parse(decrypted.toString('utf8'));
  } catch (error) {
    console.error('Decryption error:', error);
    throw new Error('Failed to decrypt webhook payload');
  }
}

/**
 * Create an encrypted response
 * @param {Object} data - The data to encrypt
 * @param {string} key - Encryption key configured in SIBS Gateway V2 Backoffice
 * @returns {string} - Encrypted data (Base64 encoded)
 */
function encryptResponse(data, key) {
  try {
    // Convert data to JSON string
    const jsonData = JSON.stringify(data);
    
    // Convert Base64 key to Buffer
    const keyBuffer = Buffer.from(key, 'base64');
    
    // Generate a random IV
    const iv = crypto.randomBytes(16);
    
    // Create cipher with key and iv
    const cipher = crypto.createCipheriv('aes-256-cbc', keyBuffer, iv);
    
    // Encrypt the data
    let encrypted = cipher.update(jsonData, 'utf8');
    encrypted = Buffer.concat([encrypted, cipher.final()]);
    
    // Prepend the IV to the encrypted data
    const result = Buffer.concat([iv, encrypted]);
    
    // Return Base64 encoded result
    return result.toString('base64');
  } catch (error) {
    console.error('Encryption error:', error);
    throw new Error('Failed to encrypt response');
  }
}

// Health check endpoint
router.get(HEALTH_PATH, (req, res) => {
  res.status(200).json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    endpoints: {
      webhook: `https://api.appbar.epvc.pt${BASE_URL}${WEBHOOK_PATH}`,
      health: `https://api.appbar.epvc.pt${BASE_URL}${HEALTH_PATH}`,
      test: `https://api.appbar.epvc.pt${BASE_URL}${TEST_PATH}`
    }
  });
});

// Test endpoint
router.post(TEST_PATH, (req, res) => {
  try {
    // Get payment method from query param or default to CARD
    const paymentMethod = req.query.method || 'CARD';
    const paymentType = req.query.type || 'PURS';
    const status = req.query.status || 'Success';
    
    let testData = {
      returnStatus: {
        statusMsg: status,
        statusCode: status === "Success" ? "000" : "01.106.0004"
      },
      paymentStatus: status,
      paymentMethod: paymentMethod,
      transactionID: `s2${Math.random().toString(36).substring(7)}`,
      transactionDateTime: new Date().toISOString(),
      amount: {
        currency: "EUR",
        value: 19.20
      },
      merchant: {
        transactionId: `863b730df285443ca404e008${Math.random().toString(36).substring(7)}`,
        terminalId: 66645,
        merchantName: `Teste ${paymentMethod}, Lda`,
        inApp: false
      },
      paymentType: paymentType,
      internalTransactionId: `S${Date.now()}S`,
      notificationID: `${Math.random().toString(36).substring(7)}-${Date.now()}`
    };

    // Add payment method specific fields
    switch(paymentMethod) {
      case 'MBWAY':
        testData = {
          ...testData,
          token: {
            tokenType: "MobilePhone",
            value: "351#912345678"
          },
          mbwayMandate: paymentType === 'AUTH' ? {
            mandateIdentification: "12345690656800744652",
            mandateAction: "CRTN",
            mandateActionStatus: "SCCS",
            mandateType: "SBSC",
            clientName: "Test Client",
            aliasMBWAY: "351#912345678",
            mandateExpirationDate: "2027-12-31",
            mandateAmountLimit: {
              value: "100.00",
              currency: "EUR"
            }
          } : undefined
        };
        break;

      case 'CARD':
        if (paymentType === 'MITR') {
          testData.merchantInitiatedTransaction = {
            type: "RCRR",
            amountQualifier: "ACTUAL",
            schedule: {
              initialDate: new Date().toISOString(),
              finalDate: new Date(Date.now() + 30*24*60*60*1000).toISOString(),
              interval: "MONTHLY"
            }
          };
        }
        break;

      case 'REFERENCE':
        if (paymentType === 'PREF') {
          testData.paymentReference = {
            reference: "256309828",
            entity: "40200",
            paymentEntity: "40200",
            amount: {
              value: "19.20",
              currency: "EUR"
            },
            status: status === "Success" ? "PAID" : "UNPAID",
            expiryDate: new Date(Date.now() + 30*24*60*60*1000).toISOString()
          };
        }
        break;

      case 'TOKEN':
        testData.token = {
          tokenType: "Card",
          value: `tok_${Math.random().toString(36).substring(7)}`,
          maskedPAN: "401200******1112",
          expireDate: new Date(Date.now() + 365*24*60*60*1000).toISOString()
        };
        break;

      case 'STATIC_QRCODE':
        testData.financialOperation = {
          product: {
            staticQRCodeId: `qr_${Math.random().toString(36).substring(7)}`,
            twoStepPurchase: false,
            aliasName: "351#934885128",
            merchantContactType: "NA",
            productName: "Test Product",
            productQuantity: 1,
            productAmount: 19.20,
            expeditionAmount: 0.00,
            contactClientIndicator: 1,
            customerSupportContact: "support@test.com"
          },
          billingInfo: {
            billingTIN: "123456789",
            billingAddressCity: "Lisboa",
            billingAddressLine1: "Test Street",
            billingAddressLine2: "123",
            billingAddressPostalCode: "1000-100",
            billingMobilePhone: "351912345678"
          }
        };
        break;
    }

    // Try to encrypt the test data
    const encryptedData = encryptResponse(testData, ENCRYPTION_KEY);
    const decryptedData = decryptWebhook(encryptedData, ENCRYPTION_KEY);
    
    res.status(200).json({
      status: "Success",
      message: `${paymentMethod} ${paymentType} test data generated`,
      webhookUrl: `https://api.appbar.epvc.pt${BASE_URL}${WEBHOOK_PATH}`,
      original: testData,
      encrypted: encryptedData,
      decrypted: decryptedData,
      curlCommands: {
        raw: `curl -X POST "https://api.appbar.epvc.pt${BASE_URL}${WEBHOOK_PATH}" -H "Content-Type: application/json" -d '${JSON.stringify(testData)}'`,
        encrypted: `curl -X POST "https://api.appbar.epvc.pt${BASE_URL}${WEBHOOK_PATH}" -H "Content-Type: application/json" -d '{"encryptedData":"${encryptedData}"}'`
      }
    });
  } catch (error) {
    res.status(500).json({
      status: "Error",
      message: "Test data generation failed",
      error: error.message
    });
  }
});

// Add max retries and check interval constants
const MAX_STATUS_CHECK_RETRIES = 5; // Maximum number of status check retries
const STATUS_CHECK_INTERVAL = 60000; // 1 minute interval between checks

// Add new endpoint for initial transaction registration
router.post('/sibs/initial', async (req, res) => {
  try {
    const { transactionID, transactionSignature } = req.body;

    // Validate required fields
    if (!transactionID || !transactionSignature) {
      return res.status(400).json({
        status: 'Error',
        message: 'transactionID and transactionSignature are required'
      });
    }

    const connection = await pool.getConnection();
    
    try {
      // Save initial transaction data
      await connection.query(
        `INSERT INTO transactions 
        (transaction_id, transaction_signature, payment_status, transaction_datetime) 
        VALUES (?, ?, 'Pending', NOW())`,
        [transactionID, transactionSignature]
      );


      // Start status check process
      let retryCount = 0;
      const checkStatus = async () => {
        try {
          // Check if we already received a webhook
          const [rows] = await connection.query(
            'SELECT payment_status FROM transactions WHERE transaction_id = ?',
            [transactionID]
          );

          const transaction = rows[0];
          const currentStatus = transaction?.payment_status;

          // Only check status if transaction exists and status hasn't changed from initial state
          if (transaction && currentStatus === 'Pending') {
            console.log(`Checking status for ${transactionID} (attempt ${retryCount + 1}/${MAX_STATUS_CHECK_RETRIES})`);
            
            try {
              // Call SIBS getStatus API
              const response = await fetch(
                `https://api.qly.sibspayments.com/sibs/spg/v2/payments/${transactionID}/status`,
                {
                  method: 'GET',
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${AUTHORIZATION_API}`,
                    'X-IBM-Client-Id': CLIENT_ID
                  }
                }
              );

              if (!response.ok) {
                throw new Error(`Status check failed: ${response.status} ${response.statusText}`);
              }

              const statusData = await response.json();
              
              // If status is different from current status, update it
              if (statusData.paymentStatus !== currentStatus) {
                await connection.query(
                  `UPDATE transactions 
                  SET 
                    payment_status = ?,
                    payment_method = ?,
                    payment_type = ?,
                    amount_value = ?,
                    amount_currency = ?,
                    merchant_transaction_id = ?,
                    merchant_terminal_id = ?,
                    merchant_name = ?,
                    updated_at = NOW()
                  WHERE transaction_id = ?`,
                  [
                    statusData.paymentStatus,
                    statusData.paymentMethod,
                    statusData.paymentType,
                    statusData.amount?.value,
                    statusData.amount?.currency,
                    statusData.merchant?.transactionId,
                    statusData.merchant?.terminalId,
                    statusData.merchant?.merchantName,
                    transactionID
                  ]
                );

              } else {
                
                // Schedule next check if we haven't reached max retries
                retryCount++;
                if (retryCount < MAX_STATUS_CHECK_RETRIES) {
                  setTimeout(checkStatus, STATUS_CHECK_INTERVAL);
                } else {
                  console.log(`Max retries reached for transaction ${transactionID}`);
                }
              }
            } catch (statusError) {
              
              // Schedule next check if we haven't reached max retries
              retryCount++;
              if (retryCount < MAX_STATUS_CHECK_RETRIES) {
                setTimeout(checkStatus, STATUS_CHECK_INTERVAL);
              } else {
                // Update transaction to indicate status check failed after max retries
                await connection.query(
                  `UPDATE transactions 
                  SET 
                    payment_status = 'Error',
                    updated_at = NOW()
                  WHERE transaction_id = ?`,
                  [transactionID]
                );
              }
            }
          }
        } catch (error) {
        }
      };

      // Start first check after 4 minutes
      setTimeout(checkStatus, 240000);

      // Send success response
      res.status(200).json({
        status: 'Success',
        message: 'Transaction registered successfully',
        transactionID,
        timeoutMessage: 'You have 4 minutes to approve the payment in MB WAY app'
      });

    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('Error registering transaction:', error);
    res.status(500).json({
      status: 'Error',
      message: 'Internal server error',
      error: error.message
    });
  }
});

// GET handler for status endpoint
router.get(`${STATUS_PATH}/:transactionId`, async (req, res) => {
  try {
    const { transactionId } = req.params;
    
    // Get connection from pool
    const connection = await pool.getConnection();
    
    try {
      // Query the transaction status
      const [rows] = await connection.execute(
        'SELECT * FROM transactions WHERE transaction_id = ? ORDER BY created_at DESC LIMIT 1',
        [transactionId]
      );

      if (rows.length === 0) {
        return res.status(404).json({
          status: 'Not Found',
          message: 'Transaction not found',
          transactionId
        });
      }

      const transaction = rows[0];

      // Format the response
      const response = {
        status: transaction.status,
        paymentStatus: transaction.payment_status,
        transactionStatusCode: transaction.status_code,
        orderNumber: transaction.order_number,
        amount: {
          value: parseFloat(transaction.amount),
          currency: transaction.currency
        },
        returnStatus: {
          message: transaction.status_message,
          code: transaction.status_code
        },
        rawResponse: JSON.parse(transaction.raw_response || '{}')
      };

      res.json(response);
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('Error checking status:', error);
    res.status(500).json({
      status: 'Error',
      message: 'Internal server error while checking payment status',
      error: error.message
    });
  }
});

// Mount the router on the BASE_URL
app.use(BASE_URL, router);

// Add error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ 
    statusCode: "500",
    statusMsg: "Internal Server Error",
    notificationID: req.body?.notificationID || ""
  });
});

// Add 404 handler - this should be last
app.use((req, res) => {
  console.log('404 Not Found:', req.method, req.url);
  const isApiRequest = req.url.startsWith(BASE_URL);
  
  if (isApiRequest) {
    res.status(404).json({ 
      statusCode: "404",
      statusMsg: "Not Found",
      path: req.url,
      availableEndpoints: {
        webhook: {
          url: `https://api.appbar.epvc.pt${BASE_URL}${WEBHOOK_PATH}`,
          methods: ["POST"]
        },
        health: {
          url: `https://api.appbar.epvc.pt${BASE_URL}${HEALTH_PATH}`,
          methods: ["GET"]
        },
        test: {
          url: `https://api.appbar.epvc.pt${BASE_URL}${TEST_PATH}`,
          methods: ["POST"]
        }
      }
    });
  } else {
    res.status(404).json({ 
      statusCode: "404",
      statusMsg: "Not Found",
      path: req.url,
      message: "Please use the API endpoints under /api"
    });
  }
});

// Update the startup message
app.listen(PORT, () => {
  console.log(`SIBS Gateway V2 Webhook server running on port ${PORT}`);
  console.log(`Base URL: ${BASE_URL}`);
  console.log(`Webhook endpoint: https://api.appbar.epvc.pt${BASE_URL}${WEBHOOK_PATH}`);
  console.log(`Status endpoint: https://api.appbar.epvc.pt${BASE_URL}${STATUS_PATH}/{transactionId}`);
  console.log(`Health endpoint: https://api.appbar.epvc.pt${BASE_URL}${HEALTH_PATH}`);
  console.log(`Test endpoint: https://api.appbar.epvc.pt${BASE_URL}${TEST_PATH}`);
  console.log(`Make sure to configure TLS 1.2 and port 80/443 for production use`);
});

