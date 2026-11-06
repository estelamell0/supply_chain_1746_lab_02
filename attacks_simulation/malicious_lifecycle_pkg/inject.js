/**
 * Script de Injeção Maliciosa em Tempo de Instalação (Simulação Controlada de Lab)
 * Demonstra como agentes maliciosos utilizam o gancho 'postinstall' do npm
 * para coletar variáveis de ambiente sensíveis (ex: GITHUB_TOKEN, AWS_KEYS).
 */

const fs = require('fs');
const os = require('os');
const path = require('path');

const logPath = path.resolve(__dirname, '../exfiltrated_data.log');

// Garantir variáveis simuladas de esteira CI/CD caso o container/host não as tenha exportado
const envContext = Object.assign({
    USER: os.userInfo().username || 'root',
    HOSTNAME: os.hostname(),
    GITHUB_TOKEN: 'ghp_SimulatedPipelineToken9876543210abcdef',
    AWS_SECRET_ACCESS_KEY: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
    NPM_TOKEN: 'npm_SimulatedInternalRegistryToken12345'
}, process.env);

const targetKeys = Object.keys(envContext).filter(key =>
    key.includes('TOKEN') ||
    key.includes('KEY') ||
    key.includes('SECRET') ||
    key.includes('USER') ||
    key.includes('HOST') ||
    key.includes('HOME') ||
    key.includes('PATH')
);

const capturedSecrets = {};
for (const k of targetKeys) {
    const val = String(envContext[k] || '');
    capturedSecrets[k] = val.length > 60 ? val.substring(0, 60) + '...' : val;
}

const simulatedLeak = {
    incident: 'MALICIOUS_LIFECYCLE_EXECUTION',
    timestamp: new Date().toISOString(),
    process_pid: process.pid,
    runner_identity: `${envContext.USER}@${envContext.HOSTNAME}`,
    environment_variables_captured: targetKeys,
    exfiltrated_values_sample: capturedSecrets,
    warning: '[ALERTA DE SEGURANÇA] Código não autorizado executado no host durante o ciclo npm install!'
};

fs.writeFileSync(logPath, JSON.stringify(simulatedLeak, null, 2) + '\n', { encoding: 'utf-8' });

console.log('\x1b[31m%s\x1b[0m', '------------------------------------------------------------------------');
console.log('\x1b[31m%s\x1b[0m', '[ALERTA CRÍTICO] Gancho POSTINSTALL malicioso executado com sucesso!');
console.log('\x1b[33m%s\x1b[0m', `Evidência gravada em: ${logPath}`);
console.log('\x1b[31m%s\x1b[0m', '------------------------------------------------------------------------');
