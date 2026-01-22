export type NcrEmailTemplate = {
  subject: string;
  htmlContent: string;
};

export function lowLevelReminder(dueDate: string): NcrEmailTemplate {
  return {
    subject: "NCR Reminder – Action Required (Due on " + dueDate + ")",
    htmlContent: `
      <p>Dear Team,</p>

      <p>
        This is a reminder that the following
        <strong>Non-Conformance Report (NCR)</strong>
        is approaching its due date.
      </p>

      <p><strong>Due Date:</strong> ${dueDate}</p>

      <p>
        Please ensure the corrective actions are
        completed on time.
      </p>

      <p>
        Regards,<br />
        <strong>NCR Monitoring System</strong>
      </p>
    `,
  };
}

export function mediumLevelEscalation(dueDate: string): NcrEmailTemplate {
  return {
    subject: "NCR Escalation Notice – Pending (Due on " + dueDate + ")",
    htmlContent: `
      <p>Dear Team,</p>

      <p>
        The following
        <strong>Non-Conformance Report (NCR)</strong>
        is still pending and has reached or crossed
        its due date.
      </p>

      <p><strong>Due Date:</strong> ${dueDate}</p>

      <p>
        Immediate attention is required to avoid
        further escalation.
      </p>

      <p>
        Regards,<br />
        <strong>NCR Monitoring System</strong>
      </p>
    `,
  };
}

export function topLevelCriticalEscalation(dueDate: string): NcrEmailTemplate {
  return {
    subject: "Critical NCR Escalation – Immediate Action Required",
    htmlContent: `
      <p>Dear Management,</p>

      <p>
        This is a <strong>critical escalation</strong>
        for an overdue
        <strong>Non-Conformance Report (NCR)</strong>.
      </p>

      <p><strong>Original Due Date:</strong> ${dueDate}</p>

      <p>
        The NCR remains unresolved despite
        previous reminders.
      </p>

      <p>
        Your immediate intervention is requested.
      </p>

      <p>
        Regards,<br />
        <strong>NCR Monitoring System</strong>
      </p>
    `,
  };
}
