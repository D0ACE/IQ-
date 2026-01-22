import moment from "moment";

export function daysDiff(dueDate: string): number {
  const due = moment(dueDate, "DD-MM-YYYY");
  const today = moment().startOf("day");
  return due.diff(today, "days");
}
