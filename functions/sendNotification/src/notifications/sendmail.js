// This code requires the @sendgrid/mail package to be installed (npm install @sendgrid/mail)
const sgMail = require('@sendgrid/mail');
const config = require('../config');

async function sendmail() {
    // Retrieve SendGrid API Key from environment variables (best practice)
    sgMail.setApiKey(config.sgapikey);

    // Get email details from the event object or use defaults/environment variables
    const toEmail = config.tomailid; // Recipient email address
    const fromEmail = config.frommailid; // Verified Sender email address
    const subject = 'Email from Lambda using SendGrid Library';
    const textBody = 'This is the plain text content.';
    const htmlBody = '<p>This is the <strong>HTML</strong> content.</p>';

    if (!config.sgapikey || !fromEmail || !toEmail) {
         console.error("Missing required information: API Key, From Email, or To Email.");
         return {
             statusCode: 400,
             body: JSON.stringify({ message: 'Missing SendGrid API Key, sender email, or recipient email.' }),
         };
    }

    const msg = {
        to: toEmail,
        from: fromEmail, // Use your verified sender email here
        subject: subject,
        text: textBody,
        html: htmlBody,
    };

    await sgMail.send(msg);
    console.log('Email sent successfully using @sendgrid/mail');
};

module.exports = {
    sendmail
};
