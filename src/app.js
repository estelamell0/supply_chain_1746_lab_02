/**
 * Payment API Microservice (Ada Tech Supply Chain Security Lab 02)
 * Simula um serviço corporativo de processamento de transações financeiras.
 */

const express = require('express');
const lodash = require('lodash');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// Rota de saúde (Healthcheck)
app.get('/health', (req, res) => {
    res.json({
        status: 'UP',
        service: 'payment-api-service',
        timestamp: new Date().toISOString()
    });
});

// Endpoint de processamento de pagamentos
app.post('/api/v1/payments', (req, res) => {
    const { amount, currency, recipient } = req.body;

    if (!amount || !currency || !recipient) {
        return res.status(400).json({ error: 'Parâmetros obrigatórios ausentes.' });
    }

    // Utiliza lodash para clonar e mesclar metadados da transação
    const transaction = lodash.merge({}, req.body, {
        id: `tx_${Date.now()}`,
        status: 'APPROVED',
        processed_at: new Date().toISOString()
    });

    console.log(`[PAYMENT] Transação processada: ${transaction.id} para ${recipient}`);
    return res.status(201).json(transaction);
});

if (require.main === module) {
    app.listen(PORT, () => {
        console.log(`[INFO] Payment API rodando na porta ${PORT}`);
    });
}

module.exports = app;

