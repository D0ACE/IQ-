import axios from "axios";
import {BREVO_API_URL} from "../config/brevo";

/**
 * Service to handle Brevo Email operations.
 */
export class BrevoEmailService {
  /**
   * Sends a document review request email to the assigned reviewer.
   * @param {string} to Reviewer email
   * @param {string} reviewerName Reviewer name
   * @param {string} docTitle Document title
   */
  static async sendReviewRequest(
    to: string,
    reviewerName: string,
    docTitle: string
  ) {
    const subject = `Annual Review Required: ${docTitle}`;
    const htmlContent = `
      <html>
        <body>
          <h2>Policy & Procedure Annual Review</h2>
          <p>Hello ${reviewerName},</p>
          <p>The document <strong>"${docTitle}"</strong> has reached
             its annual anniversary and requires your review.</p>
          <p>Please log in to the IQ Plus portal to review this document.</p>
          <p>Thank you,<br>System Administrator</p>
        </body>
      </html>
    `;

    try {
      await axios.post(
        BREVO_API_URL,
        {
          sender: {
            name: "IQ Plus",
            email: "iqplusproject@gmail.com",
          },
          to: [{email: to}],
          subject,
          htmlContent,
        },
        {
          headers: {
            "api-key": process.env.BREVO_API_KEY!,
            "content-type": "application/json",
          },
        }
      );
      console.log(`📧 Review request email sent to ${to}`);
    } catch (error) {
      console.error(`❌ Failed to send review email to ${to}:`, error);
    }
  }

  /**
   * Sends a templated email via Brevo.
   * @param {number} templateId Brevo Template ID
   * @param {string} to Receiver email
   * @param {string} toName Receiver name
   * @param {object} params Template parameters
   */
  static async sendTemplateEmail(
    templateId: number,
    to: string,
    toName: string,
    params: any
  ) {
    try {
      await axios.post(
        BREVO_API_URL,
        {
          to: [{email: to, name: toName}],
          templateId: templateId,
          params: params,
        },
        {
          headers: {
            "api-key": process.env.BREVO_API_KEY!,
            "content-type": "application/json",
          },
        }
      );
      console.log(`📧 Template ${templateId} sent to ${to}`);
    } catch (error: any) {
      console.error(`❌ Brevo API Error (${templateId}):`,
                    error.response?.data || error.message);
      throw error;
    }
  }
}
