const { sendmail } = require("./src/notifications/sendmail");


exports.handler = async (event) => {
    
    try {
        await sendmail();
        return {
            statusCode: 200,
            body: JSON.stringify({ message: 'Email sent successfully!' }),
        };
    } catch (error) {
        console.error('Error sending email with @sendgrid/mail:', error);
        // Log specific SendGrid error details if available
        if (error.response) {
            console.error('SendGrid Error Response Body:', error.response.body);
        }
        return {
            statusCode: error.statusCode || 500,
            body: JSON.stringify({
                message: 'Failed to send email using SendGrid library.',
                error: error.message,
                sendGridError: error.response ? error.response.body : 'N/A'
            }),
        };
    }
};