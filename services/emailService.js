import sgMail from '@sendgrid/mail';
import dotenv from 'dotenv';

dotenv.config();

// Configure SendGrid
sgMail.setApiKey(process.env.SENDGRID_API_KEY || 'SG.your_api_key_here');

class EmailService {
  static FROM_EMAIL = process.env.FROM_EMAIL || 'noreply@fitnessaas.com';
  static FROM_NAME = process.env.FROM_NAME || 'Fitness SaaS';

  // Send welcome email to new users
  static async sendWelcomeEmail(userEmail, userName, userType) {
    const msg = {
      to: userEmail,
      from: {
        email: this.FROM_EMAIL,
        name: this.FROM_NAME,
      },
      subject: '🏋️‍♂️ Bem-vindo ao Fitness SaaS!',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #4A90E2 0%, #357ABD 100%); padding: 40px; text-align: center; color: white;">
            <h1 style="margin: 0; font-size: 32px;">🏋️‍♂️ Fitness SaaS</h1>
            <p style="margin: 10px 0 0 0; font-size: 18px;">Sistema de Gestão de Treinos</p>
          </div>
          
          <div style="padding: 40px 30px; background: #f8f9fa;">
            <h2 style="color: #333; margin-bottom: 20px;">Olá ${userName}!</h2>
            
            <p style="color: #666; line-height: 1.6; font-size: 16px;">
              Seja bem-vindo(a) ao <strong>Fitness SaaS</strong>! Estamos muito felizes em tê-lo(a) conosco.
            </p>
            
            ${this.getWelcomeContentByUserType(userType)}
            
            <div style="text-align: center; margin: 30px 0;">
              <a href="${process.env.FRONTEND_URL || 'http://localhost:3000'}" 
                 style="background: #4A90E2; color: white; padding: 15px 30px; 
                        text-decoration: none; border-radius: 5px; font-weight: bold;">
                Acessar Plataforma
              </a>
            </div>
            
            <div style="background: #e3f2fd; padding: 20px; border-radius: 8px; margin: 20px 0;">
              <h3 style="color: #1976d2; margin-top: 0;">🎯 Próximos Passos:</h3>
              <ul style="color: #666; line-height: 1.6;">
                <li>Complete seu perfil</li>
                <li>Explore as funcionalidades da plataforma</li>
                <li>Configure suas preferências</li>
                ${userType === 'trainer' ? '<li>Adicione seus primeiros alunos</li>' : ''}
                ${userType === 'athlete' ? '<li>Aguarde a atribuição dos treinos</li>' : ''}
                ${userType === 'nutritionist' ? '<li>Crie seus primeiros planos alimentares</li>' : ''}
              </ul>
            </div>
          </div>
          
          <div style="background: #333; color: #ccc; padding: 20px; text-align: center; font-size: 14px;">
            <p>© 2025 Fitness SaaS. Todos os direitos reservados.</p>
            <p>Se você não criou esta conta, pode ignorar este email.</p>
          </div>
        </div>
      `,
    };

    try {
      await sgMail.send(msg);
      console.log(`✅ Welcome email sent to ${userEmail}`);
    } catch (error) {
      console.error(`❌ Failed to send welcome email: ${error.message}`);
      throw error;
    }
  }

  // Send workout notification
  static async sendWorkoutNotification(userEmail, userName, workoutName, scheduledDate) {
    const msg = {
      to: userEmail,
      from: {
        email: this.FROM_EMAIL,
        name: this.FROM_NAME,
      },
      subject: `💪 Novo Treino Disponível: ${workoutName}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: #4CAF50; padding: 30px; text-align: center; color: white;">
            <h1 style="margin: 0;">💪 Novo Treino!</h1>
          </div>
          
          <div style="padding: 30px; background: #f8f9fa;">
            <h2 style="color: #333;">Olá ${userName}!</h2>
            
            <p style="color: #666; font-size: 16px;">
              Você tem um novo treino disponível na plataforma:
            </p>
            
            <div style="background: white; padding: 20px; border-radius: 8px; border-left: 4px solid #4CAF50;">
              <h3 style="color: #4CAF50; margin-top: 0;">${workoutName}</h3>
              <p style="color: #666; margin: 5px 0;">
                📅 <strong>Data:</strong> ${new Date(scheduledDate).toLocaleDateString('pt-BR')}
              </p>
            </div>
            
            <div style="text-align: center; margin: 30px 0;">
              <a href="${process.env.FRONTEND_URL || 'http://localhost:3000'}/workouts" 
                 style="background: #4CAF50; color: white; padding: 15px 30px; 
                        text-decoration: none; border-radius: 5px; font-weight: bold;">
                Ver Treino Completo
              </a>
            </div>
          </div>
        </div>
      `,
    };

    try {
      await sgMail.send(msg);
      console.log(`✅ Workout notification sent to ${userEmail}`);
    } catch (error) {
      console.error(`❌ Failed to send workout notification: ${error.message}`);
      throw error;
    }
  }



  // Send subscription notification
  static async sendSubscriptionNotification(userEmail, userName, subscriptionStatus, planName) {
    const isActive = subscriptionStatus === 'active';
    const subject = isActive ? 
      `✅ Assinatura Ativada - ${planName}` : 
      `⚠️ Problema com Assinatura - ${planName}`;

    const msg = {
      to: userEmail,
      from: {
        email: this.FROM_EMAIL,
        name: this.FROM_NAME,
      },
      subject,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: ${isActive ? '#4CAF50' : '#FF6B6B'}; padding: 30px; text-align: center; color: white;">
            <h1 style="margin: 0;">${isActive ? '✅' : '⚠️'} Assinatura ${isActive ? 'Ativada' : 'Inativa'}</h1>
          </div>
          
          <div style="padding: 30px; background: #f8f9fa;">
            <h2 style="color: #333;">Olá ${userName}!</h2>
            
            <p style="color: #666; font-size: 16px;">
              ${isActive ? 
                `Sua assinatura do plano <strong>${planName}</strong> foi ativada com sucesso!` :
                `Houve um problema com sua assinatura do plano <strong>${planName}</strong>.`
              }
            </p>
            
            <div style="text-align: center; margin: 30px 0;">
              <a href="${process.env.FRONTEND_URL || 'http://localhost:3000'}/profile/subscription" 
                 style="background: ${isActive ? '#4CAF50' : '#FF6B6B'}; color: white; padding: 15px 30px; 
                        text-decoration: none; border-radius: 5px; font-weight: bold;">
                Gerenciar Assinatura
              </a>
            </div>
          </div>
        </div>
      `,
    };

    try {
      await sgMail.send(msg);
      console.log(`✅ Subscription notification sent to ${userEmail}`);
    } catch (error) {
      console.error(`❌ Failed to send subscription notification: ${error.message}`);
      throw error;
    }
  }

  // Send bulk email to multiple recipients
  static async sendBulkEmail(recipients, subject, htmlContent) {
    const msg = {
      to: recipients,
      from: {
        email: this.FROM_EMAIL,  
        name: this.FROM_NAME,
      },
      subject,
      html: htmlContent,
    };

    try {
      await sgMail.sendMultiple(msg);
      console.log(`✅ Bulk email sent to ${recipients.length} recipients`);
    } catch (error) {
      console.error(`❌ Failed to send bulk email: ${error.message}`);
      throw error;
    }
  }

  // Helper method to get welcome content by user type
  static getWelcomeContentByUserType(userType) {
    switch (userType) {
      case 'trainer':
        return `
          <p style="color: #666; line-height: 1.6;">
            Como <strong>Personal Trainer</strong>, você terá acesso a ferramentas poderosas para:
          </p>
          <ul style="color: #666; line-height: 1.6;">
            <li>🏋️‍♂️ Criar treinos personalizados para seus alunos</li>
            <li>📊 Acompanhar o progresso de cada atleta</li>
            <li>💰 Gerenciar sua assinatura mensal de R$ 49,90</li>
            <li>📈 Visualizar relatórios detalhados</li>
          </ul>
        `;
      case 'athlete':
        return `
          <p style="color: #666; line-height: 1.6;">
            Como <strong>Atleta</strong>, você poderá:
          </p>
          <ul style="color: #666; line-height: 1.6;">
            <li>💪 Receber treinos personalizados do seu treinador</li>
            <li>📱 Marcar treinos como concluídos</li>
            <li>📊 Acompanhar seu progresso e evolução</li>
            <li>🥗 Receber planos nutricionais</li>
          </ul>
        `;
      case 'nutritionist':
        return `
          <p style="color: #666; line-height: 1.6;">
            Como <strong>Nutricionista</strong>, você terá ferramentas para:
          </p>
          <ul style="color: #666; line-height: 1.6;">
            <li>🥗 Criar planos alimentares personalizados</li>
            <li>🧮 Calcular macronutrientes automaticamente</li>
            <li>📋 Gerenciar receitas e refeições</li>
            <li>👥 Acompanhar múltiplos clientes</li>
          </ul>
        `;
      default:
        return `
          <p style="color: #666; line-height: 1.6;">
            Com nossa plataforma, você terá acesso a todas as ferramentas necessárias 
            para gerenciar treinos e nutrição de forma eficiente.
          </p>
        `;
    }
  }

  // Send password reset email
  static async sendPasswordResetEmail(userEmail, userName, resetUrl) {
    
    const msg = {
      to: userEmail,
      from: {
        email: this.FROM_EMAIL,
        name: this.FROM_NAME,
      },
      subject: '🔐 Redefinição de Senha - Fitness SaaS',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #E53E3E 0%, #C53030 100%); padding: 40px; text-align: center; color: white;">
            <h1 style="margin: 0; font-size: 32px;">🔐 Redefinição de Senha</h1>
            <p style="margin: 10px 0 0 0; font-size: 18px;">Fitness SaaS</p>
          </div>
          
          <div style="padding: 40px 30px; background: #f8f9fa;">
            <h2 style="color: #333; margin-bottom: 20px;">Olá ${userName || 'Usuário'}!</h2>
            
            <p style="color: #666; line-height: 1.6; font-size: 16px;">
              Recebemos uma solicitação para redefinir a senha da sua conta no <strong>Fitness SaaS</strong>.
            </p>
            
            <div style="background: #fff3cd; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ffc107;">
              <p style="color: #856404; margin: 0; line-height: 1.6;">
                <strong>🔒 Importante:</strong> Este link é válido por apenas 1 hora por motivos de segurança.
              </p>
            </div>
            
            <div style="text-align: center; margin: 30px 0;">
              <a href="${resetUrl}" 
                 style="background: #E53E3E; color: white; padding: 15px 30px; 
                        text-decoration: none; border-radius: 5px; font-weight: bold;
                        display: inline-block;">
                Redefinir Minha Senha
              </a>
            </div>
            
            <div style="background: #f8d7da; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #dc3545;">
              <h3 style="color: #721c24; margin-top: 0;">⚠️ Não solicitou esta alteração?</h3>
              <p style="color: #721c24; margin-bottom: 0; line-height: 1.6;">
                Se você não solicitou a redefinição de senha, ignore este email. 
                Sua senha permanecerá inalterada e segura.
              </p>
            </div>
            
            <div style="border-top: 1px solid #ddd; padding-top: 20px; margin-top: 30px;">
              <p style="color: #888; font-size: 14px; text-align: center; margin: 0;">
                Este email foi enviado automaticamente. Por favor, não responda.
              </p>
              <p style="color: #888; font-size: 14px; text-align: center; margin: 10px 0 0 0;">
                © ${new Date().getFullYear()} Fitness SaaS. Todos os direitos reservados.
              </p>
            </div>
          </div>
        </div>
      `,
    };

    try {
      await sgMail.send(msg);
      console.log(`Password reset email sent to ${userEmail}`);
    } catch (error) {
      console.error('Error sending password reset email:', error);
      throw new Error('Falha ao enviar email de redefinição de senha');
    }
  }
}

// Export methods for compatibility
export const sendEmail = EmailService.sendPasswordResetEmail;
export const sendPasswordResetEmail = EmailService.sendPasswordResetEmail;
export default EmailService;