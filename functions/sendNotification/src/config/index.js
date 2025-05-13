module.exports = {
    sgapikey : process.env.SENDGRID_API_KEY,
    tomailid : process.env.TO_EMAIL,
    frommailid : process.env.FROM_EMAIL,
    awsregion : process.env.REGION,
    azqueue : {
        queuename : 'js-queue-items',
        queueurl : ''
    }
}