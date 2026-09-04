/// Maps backend / request statuses onto the mobile UI contract.
library;

String normalizeAuctionAccessStatus(String status) {
  switch (status.toUpperCase()) {
    case 'APPROVED':
    case 'AUTO_APPROVED':
    case 'GRANTED':
      return 'GRANTED';
    case 'BLOCKED':
    case 'DENIED':
      return 'DENIED';
    case 'PROFILE_INCOMPLETE':
      return 'PROFILE_INCOMPLETE';
    default:
      return status.toUpperCase();
  }
}

bool isAuctionAccessGranted(String? status) {
  return normalizeAuctionAccessStatus(status ?? '') == 'GRANTED';
}

bool isAuctionAccessDenied(String? status) {
  return normalizeAuctionAccessStatus(status ?? '') == 'DENIED';
}

bool isAuctionProfileIncomplete(String? status) {
  final normalized = normalizeAuctionAccessStatus(status ?? '');
  return normalized == 'PROFILE_INCOMPLETE';
}

bool isAuctionAccessPending(String? status) {
  final normalized = normalizeAuctionAccessStatus(status ?? '');
  return normalized == 'PENDING' || normalized == 'PROFILE_PENDING';
}
