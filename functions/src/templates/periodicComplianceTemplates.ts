export type EmailTemplate = {
  subject: string;
  htmlContent: string;
};

export function complianceReminderTemplate(
  taskTitle: string,
  dueDate: string,
  description?: string
): EmailTemplate {
  const descriptionHtml = description && description.trim().length > 0
    ? `<p><strong>Description:</strong> ${description}</p>`
    : "";

  return {
    subject: `Reminder: Compliance Task - ${taskTitle}`,
    htmlContent: `
      <p>Dear Team,</p>

      <p>
        This is a reminder for the following <strong>Periodic Compliance Task</strong>:
      </p>

      <p><strong>Title:</strong> ${taskTitle}</p>
      ${descriptionHtml}
      <p><strong>Due Date:</strong> ${dueDate}</p>

      <p>
        Please ensure that this task is completed and marked as 'Completed' in the IQ Plus portal to maintain compliance standards.
      </p>

      <p>
        Regards,<br />
        <strong>IQ Plus Compliance Monitor</strong>
      </p>
    `,
  };
}
