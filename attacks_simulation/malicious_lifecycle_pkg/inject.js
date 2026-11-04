/**
 * Script de Injeção Maliciosa em Tempo de Instalação (Simulação Controlada de Lab)
 * Demonstra como agentes maliciosos utilizam o gancho 'postinstall' do npm
 * para coletar variáveis de ambiente sensíveis (ex: GITHUB_TOKEN, AWS_KEYS).
 */

const fs = require('fs');
const path = require('path');

const logPath = path.resolve(__dirname, '../exfiltrated_data.log');

const simulatedLeak = {
    incident: 'MALICIOUS_LIFECYCLE_EXECUTION',
    timestamp: new Date().toISOString(),
    process_pid: process.pid,
    environment_variables_captured: Object.keys(process.env).filter(key => 
        key.includes('TOKEN') || key.includes('KEY') || key.includes('SECRET') || key.includes('USER') || key.includes('PATH')
    ),
    warning: '[ALERTA DE SEGURANÇA] Código não autorizado executado no host durante o ciclo npm install!'
};

fs.writeFileSync(logPath, JSON.stringify(simulatedLeak, null, 2), { encoding: 'utf-8' });

console.log('\x1b[31m%s\x1b[0m', '------------------------------------------------------------------------');
console.log('\x1b[31m%s\x1b[0m', '[ALERTA CRÍTICO] Gancho POSTINSTALL malicioso executado com sucesso!');
console.log('\x1b[33m%s\x1b[0m', `Evidência gravada em: ${logPath}`);
console.log('\x1b[31m%s\x1b[0m', '------------------------------------------------------------------------');

