import express from 'express';
import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import { sendPasswordResetEmail } from '../services/emailService.js';
import { database } from '../config/database.js';
const router = express.Router();

// Gerar token de reset de senha
function generateResetToken() {
  return crypto.randomBytes(32).toString('hex');
}

// Enviar email de reset de senha
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ error: 'Email é obrigatório' });
    }

    // Verificar se usuário existe
    const userQuery = `
      SELECT id, email, first_name, last_name 
      FROM users 
      WHERE email = ?
    `;
    
    const user = await new Promise((resolve, reject) => {
      database.get(userQuery, [email], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (!user) {
      // Por segurança, não informar que o email não existe
      return res.json({ 
        message: 'Se o email existir em nossa base de dados, as instruções de recuperação foram enviadas.' 
      });
    }

    // Gerar token de reset
    const resetToken = generateResetToken();
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 horas

    // Salvar token no banco de dados
    const insertTokenQuery = `
      INSERT OR REPLACE INTO password_reset_tokens 
      (user_id, token, expires_at, created_at) 
      VALUES (?, ?, ?, datetime('now'))
    `;

    await new Promise((resolve, reject) => {
      database.run(insertTokenQuery, [user.id, resetToken, expiresAt.toISOString()], function(err) {
        if (err) reject(err);
        else resolve();
      });
    });

    // URL de reset (em produção, usar domínio real)
    const resetUrl = `${process.env.FRONTEND_URL || 'http://localhost:3001'}/#/auth/reset-password/${resetToken}`;

    // Enviar email
    const emailHtml = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: linear-gradient(135deg, #6C63FF, #9C88FF); padding: 20px; text-align: center;">
          <h1 style="color: white; margin: 0;">Fitness SaaS</h1>
        </div>
        
        <div style="padding: 30px; background: #f9f9f9;">
          <h2 style="color: #333;">Redefinir Senha</h2>
          
          <p>Olá ${user.first_name},</p>
          
          <p>Você solicitou a redefinição da sua senha. Clique no botão abaixo para criar uma nova senha:</p>
          
          <div style="text-align: center; margin: 30px 0;">
            <a href="${resetUrl}" style="
              background-color: #6C63FF;
              color: white;
              padding: 15px 30px;
              text-decoration: none;
              border-radius: 8px;
              font-weight: bold;
              display: inline-block;
            ">
              Redefinir Senha
            </a>
          </div>
          
          <p>Ou copie e cole o link abaixo no seu navegador:</p>
          <p style="
            background: #fff;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            word-break: break-all;
            font-size: 14px;
          ">
            ${resetUrl}
          </p>
          
          <div style="
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            border-radius: 4px;
            padding: 15px;
            margin: 20px 0;
          ">
            <h4 style="margin: 0 0 10px 0; color: #856404;">⚠️ Importante:</h4>
            <ul style="margin: 0; color: #856404;">
              <li>Este link expira em 24 horas</li>
              <li>Se você não solicitou esta alteração, ignore este email</li>
              <li>Por segurança, não compartilhe este link com ninguém</li>
            </ul>
          </div>
        </div>
        
        <div style="background: #333; color: white; padding: 20px; text-align: center; font-size: 14px;">
          <p>© 2025 Fitness SaaS. Todos os direitos reservados.</p>
          <p>Este é um email automático, não responda.</p>
        </div>
      </div>
    `;

    await sendPasswordResetEmail(email, user.name, token);

    console.log(`Password reset email sent to: ${email}`);
    
    res.json({ 
      message: 'Se o email existir em nossa base de dados, as instruções de recuperação foram enviadas.' 
    });

  } catch (error) {
    console.error('Error sending reset email:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// Redefinir senha com token
router.post('/reset-password', async (req, res) => {
  try {
    const { token, password } = req.body;

    if (!token || !password) {
      return res.status(400).json({ error: 'Token e nova senha são obrigatórios' });
    }

    if (password.length < 8) {
      return res.status(400).json({ error: 'A senha deve ter pelo menos 8 caracteres' });
    }

    // Verificar se token existe e não expirou
    const tokenQuery = `
      SELECT prt.*, u.id as user_id, u.email 
      FROM password_reset_tokens prt
      JOIN users u ON prt.user_id = u.id
      WHERE prt.token = ? AND prt.expires_at > datetime('now')
    `;

    const tokenData = await new Promise((resolve, reject) => {
      database.get(tokenQuery, [token], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (!tokenData) {
      return res.status(400).json({ error: 'Token inválido ou expirado' });
    }

    // Hash da nova senha
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Atualizar senha do usuário
    const updatePasswordQuery = `
      UPDATE users 
      SET password = ?, updated_at = datetime('now')
      WHERE id = ?
    `;

    await new Promise((resolve, reject) => {
      database.run(updatePasswordQuery, [hashedPassword, tokenData.user_id], function(err) {
        if (err) reject(err);
        else resolve();
      });
    });

    // Remover token usado
    const deleteTokenQuery = `DELETE FROM password_reset_tokens WHERE token = ?`;
    
    await new Promise((resolve, reject) => {
      database.run(deleteTokenQuery, [token], function(err) {
        if (err) reject(err);
        else resolve();
      });
    });

    // Remover todos os tokens antigos do usuário por segurança
    const deleteOldTokensQuery = `
      DELETE FROM password_reset_tokens 
      WHERE user_id = ? OR expires_at <= datetime('now')
    `;
    
    await new Promise((resolve, reject) => {
      database.run(deleteOldTokensQuery, [tokenData.user_id], function(err) {
        if (err) reject(err);
        else resolve();
      });
    });

    console.log(`Password reset successful for user: ${tokenData.email}`);

    res.json({ message: 'Senha redefinida com sucesso' });

  } catch (error) {
    console.error('Error resetting password:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// Verificar validade do token (opcional, para validação frontend)
router.get('/reset-password/validate/:token', async (req, res) => {
  try {
    const { token } = req.params;

    const tokenQuery = `
      SELECT COUNT(*) as count
      FROM password_reset_tokens 
      WHERE token = ? AND expires_at > datetime('now')
    `;

    const result = await new Promise((resolve, reject) => {
      database.get(tokenQuery, [token], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    const isValid = result.count > 0;

    res.json({ valid: isValid });

  } catch (error) {
    console.error('Error validating token:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

export default router;