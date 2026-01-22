import axios from "axios";
import {BREVO_API_URL} from "../config/brevo";

export async function sendEmail(
  to: string,
  subject: string,
  htmlContent: string
) {
  await axios.post(
    BREVO_API_URL,
    {
      sender: {
        name: "IQ Plus",
        email: "iqplusproject@gmail.com", // MUST be verified in Brevo
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
}
