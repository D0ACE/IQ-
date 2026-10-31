# Implementation Plan - Policy & Procedures Flow Update

This plan outlines the changes to update the "Policy & Procedures" flow, where customers now directly approve policies, and the "assigned reviewer" concept is removed.

## User Review Required

> [!IMPORTANT]
> - The `assignedReviewerId` and `assignedReviewerName` fields will be removed from the `DocumentModel`. Existing data in Firestore will remain but will not be used or updated.
> - Customers will now be able to see `draft` policies assigned to them in their `My Policies & Procedures` list and approve them.

## Proposed Changes

### [SuperAdmin & Document Management]

#### [MODIFY] [DocumentModel](file:///C:/Users/asifk/Desktop/IQ_Plus/lib/features/superadmin/models/document_model.dart)
- Remove `assignedReviewerId` and `assignedReviewerName` from the class, constructor, `fromFirestore`, and `toFirestore`.

#### [MODIFY] [DocumentRepository](file:///C:/Users/asifk/Desktop/IQ_Plus/lib/features/superadmin/repository/document_repository.dart)
- Remove reviewer-related parameters and logic from `getDocuments`, `_addVersionHistory`, `addDocument`, `saveRichDocument`, `saveExcelBytes`, `updateDocument`, and `updateStatus`.
- Update `getDocuments` to return all documents (including `draft`) for a customer if requested, so they can approve them.
- Update `updateStatus` to properly log the customer as the approver.

#### [MODIFY] [DocumentCubit](file:///C:/Users/asifk/Desktop/IQ_Plus/lib/features/superadmin/cubit/document_cubit.dart)
- Remove `assignedReviewerId` and `assignedReviewerName` parameters from all methods (`addDocument`, `saveRichDocument`, `saveExcelDocument`, `updateDocument`).

#### [MODIFY] [DocumentAddEditPage](file:///C:/Users/asifk/Desktop/IQ_Plus/lib/features/superadmin/pages/document_add_edit_page.dart)
- Remove the "Assign Reviewer" dropdown and related state/logic.

#### [MODIFY] [DocumentEditorPage](file:///C:/Users/asifk/Desktop/IQ_Plus/lib/features/superadmin/pages/document_editor_page.dart)
- Remove the "Assign Reviewer" dropdown and related state/logic.

#### [MODIFY] [ExcelEditorPage](file:///C:/Users/asifk/Desktop/IQ_Plus/lib/features/superadmin/pages/excel_editor_page.dart)
- Remove the "Assign Reviewer" dropdown and related state/logic.

#### [MODIFY] [DocumentListPage](file:///C:/Users/asifk/Desktop/IQ_Plus/lib/features/superadmin/pages/document_list_page.dart)
- Remove reviewer information from the UI.
- Update authorization check for status changes to include Customers for their own documents.

---

### [Customer Features]

#### [MODIFY] [CustomerPolicyListPage](file:///C:/Users/asifk/Desktop/IQ_Plus/lib/features/customer_policies/pages/customer_policy_list_page.dart)
- Update `initState` to load all documents for the customer (not just active).
- Update UI to show "Draft / Pending Approval" status.
- Add an "Approve" button for draft policies that calls `DocumentCubit.updateStatus(docId, 'active')`.

---

### [Cloud Functions]

#### [MODIFY] [index.ts](file:///C:/Users/asifk/Desktop/IQ_Plus/functions/src/index.ts)
- Update `annualDocumentReviewTask` to remove reviewer logic.
- Change the notification recipient from the assigned reviewer to the Customer associated with the document.

## Verification Plan

### Automated Tests
- I will perform manual verification by checking the UI and logs, as automated tests for this flow are not currently present.

### Manual Verification
- Verify that the "Assign Reviewer" dropdown is gone from all document creation/edit pages.
- Verify that a policy uploaded for a customer appears in their list as "DRAFT".
- Verify that the customer can approve the policy, which changes its status to "ACTIVE" and creates a version history entry.
- Verify that the "Reviewer" information is removed from the `DocumentListPage`.
- Verify (mentally/code review) that the Firebase function now targets the customer.
