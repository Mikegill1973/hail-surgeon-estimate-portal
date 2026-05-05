export type UserRole = 'admin' | 'qc_manager' | 'estimator' | 'customer';

export const STATUS_OPTIONS = [
  'New Upload','Assigned','Started','Waiting on Missing Info','Customer Uploaded Missing Info','Rewrite Completed','QC Review','Revision Needed','Approved / Customer Ready','Cancelled'
] as const;

export const PRIORITY_OPTIONS = ['Standard','Rush','Same Day','Hold','Waiting on Customer','Waiting on Insurance Info'] as const;
export const QC_STATUS_OPTIONS = ['Not Reviewed','In Review','Approved','Needs Correction','Rejected','Customer Ready'] as const;
