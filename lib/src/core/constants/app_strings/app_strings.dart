/// {@category Constants}
///
/// Registry of all string keys used for localization and UI text.
/// 
/// This class centralizes all hardcoded identifiers that map to the app's 
/// internationalization (i18n) system. Using these constants prevents 
/// "magic strings" and ensures consistency across different features.
class AppStrings {
  // ── Core & Branding ────────────────────────────────────────────────────────
  
  /// The localizable key for the application name.
  static const String appName = "appName";
  
  /// Identifier for the 'Player' user type or role.
  static const String player = "player";
  
  /// Identifier for the 'Coach' user type or role.
  static const String coach = "coach";
  
  /// Identifier for the 'Store' user type or role.
  static const String store = "store";
  
  /// Key for "Profile Picture" label.
  static const String profilePicture = "profilePicture";
  
  /// Key for "ID Picture" label.
  static const String idPicture = "idPicture";
  
  /// Key for "Store Picture" label.
  static const String storePicture = "storePicture";
  
  /// Key for "Tax Card Picture" label.
  static const String taxCardPicture = "taxCardPicture";
  
  /// Key for "First Name" input field.
  static const String firstName = "firstName";
  
  /// Key for "Last Name" input field.
  static const String lastName = "lastName";
  
  /// Key for "Email" input field.
  static const String email = "email";
  
  /// Key for "Password" input field.
  static const String password = "password";
  
  /// Key for "Phone Number" input field.
  static const String phone = "phone";
  
  // ── Authentication ─────────────────────────────────────────────────────────
  
  static const String signUp = "signUp";
  static const String alreadyHaveAnAccount = "alreadyHaveAnAccount";
  static const String signIn = "signIn";
  static const String forgotPassword = "forgotPassword";
  static const String dontHaveAccount = "dontHaveAccount";
  static const String createAccount = "createAccount";
  static const String continueAsGuest = "continueAsGuest";
  static const String categories = "categories";
  static const String auctions = "auctions";
  static const String hi = "hi";
  static const String poweredBy = "poweredBy";
  static const String turathyCo = "turathyCo";
  static const String allRightsReserved = "allRightsReserved";
  static const String version = "version";
  static const String profileAndSettings = "profileAndSettings";
  static const String changeTheme = "changeTheme";
  static const String chooseTheme = "chooseTheme";
  static const String defaultTheme = "defaultTheme";
  static const String darkMode = "darkMode";
  static const String changeLanguage = "changeLanguage";
  static const String userDetails = "userDetails";
  static const String editProfile = "editProfile";
  static const String name = "name";
  static const String signOut = "signOut";
  
  /// Confirmation prompt before logging out.
  /// Kept for ProfileScreen compatibility.
  static const String areYouSureToSignOut = "areYouSureToSignOut";
  
  static const String cancel = "cancel";
  static const String holdPressToDeleteAccount = "holdPressToDeleteAccount";
  static const String deleteAccount = "deleteAccount";
  static const String areYouSureToDeleteAccount = "areYouSureToDeleteAccount";
  static const String delete = "delete";
  static const String pleaseSignInOrCreateAccount = "pleaseSignInOrCreateAccount";
  static const String contactUs = "contactUs";
  static const String myOrders = "myOrders";
  static const String pending = "pending";
  static const String completed = "completed";
  static const String retry = "retry";
  static const String orderPlacedAt = "orderPlacedAt";
  static const String id = "id";
  static const String items = "items";
  static const String updatedAt = "updatedAt";
  static const String details = "details";
  static const String orderCanceled = "orderCanceled";
  static const String total = "total";
  static const String orderDetails = "orderDetails";
  static const String status = "status";
  static const String searchAuctions = "searchAuctions";
  static const String filters = "filters";
  static const String noThingFound = "noThingFound";
  static const String sale = "sale";
  static const String sizes = "sizes";
  static const String colors = "colors";
  static const String quantity = "quantity";
  static const String successAddedToCart = "successAddedToCart";
  static const String outOfStock = "outOfStock";
  static const String inStock = "inStock";
  static const String onlyLeft = "onlyLeft";
  static const String stockAvailable = "stockAvailable";
  static const String discountPercentOff = "discountPercentOff";
  static const String addToCart = "addToCart";
  static const String addToPreorder = "addToPreorder";
  static const String preorder = "preorder";
  static const String preorderList = "preorderList";
  static const String availableByPreorder = "availableByPreorder";
  static const String priceOnRequest = "priceOnRequest";
  static const String submitPreorderRequest = "submitPreorderRequest";
  static const String preorderSubmitted = "preorderSubmitted";
  static const String preorderEmpty = "preorderEmpty";
  static const String signInToPreorder = "signInToPreorder";
  static const String offers = "offers";
  static const String allOffers = "allOffers";
  static const String applyFilters = "applyFilters";
  static const String clearFilters = "clearFilters";
  static const String cart = "cart";
  static const String orderSummary = "orderSummary";
  static const String clearCart = "clearCart";
  static const String noItemsInCart = "noItemsInCart";
  static const String city = "city";
  static const String selectCityToProceed = "selectCityToProceed";
  static const String cashOnDelivery = "cashOnDelivery";
  static const String phone_numberCopiedToClipboard = "phone_numberCopiedToClipboard";
  static const String vodafoneCash = "vodafoneCash";
  static const String pleaseCopyThePhone = "pleaseCopyThePhone";
  static const String orderPlacedSuccessfully = "orderPlacedSuccessfully";
  static const String next = "next";
  static const String enterYourAddress = "enterYourAddress";
  static const String district = "district";
  static const String street = "street";
  static const String buildingNO = "buildingNO";
  static const String submitOrder = "submitOrder";
  static const String resetPassword = "resetPassword";
  static const String enterYourEmailToResetPassword = "enterYourEmailToResetPassword";
  static const String enterYourPhoneToResetPassword = "enterYourPhoneToResetPassword";
  static const String sendCode = "sendCode";
  static const String enterCodeAndPassword = "enterCodeAndPassword";
  static const String code = "code";
  static const String pleaseEnterTheCode = "pleaseEnterTheCode";
  static const String newPassword = "newPassword";
  static const String pleaseEnterTheNewPassword = "pleaseEnterTheNewPassword";
  static const String confirmPassword = "confirmPassword";
  static const String pleaseEnterTheConfirmPassword = "pleaseEnterTheConfirmPassword";
  static const String passwordsDoNotMatch = "passwordsDoNotMatch";
  static const String resetPasswordSuccess = "resetPasswordSuccess";
  static const String home = "home";
  static const String search = "search";
  static const String myAuctions = "myAuctions";
  static const String profile = "profile";
  static const String waitingForApproval = "waitingForApproval";
  static const String waitingForApprovalMessage = "waitingForApprovalMessage";
  static const String ok = "ok";
  static const String legalInformation = "legalInformation";
  static const String privacyPolicy = "privacyPolicy";
  static const String termsAndConditions = "termsAndConditions";
  static const String price = "price";
  static const String startedAt = "startedAt";
  static const String endedAt = "endedAt";
  static const String endedOn = "endedOn";
  static const String minBidPrice = "minBidPrice";
  static const String bidPrice = "bidPrice";
  static const String currentProduct = "currentProduct";
  static const String joinNow = "joinNow";
  static const String auctionProducts = "auctionProducts";
  static const String comments = "comments";
  static const String writeComment = "writeComment";
  
  // ── Auctions ───────────────────────────────────────────────────────────────
  
  static const String liveAuctions = "liveAuctions";
  static const String openAuctions = "openAuctions";
  static const String currentAuctions = "currentAuctions";
  static const String futureAuctions = "futureAuctions";
  static const String endingSoonAuctions = "endingSoonAuctions";
  static const String auctionType = "auctionType";
  static const String winningAuctions = "winningAuctions";
  static const String orderConfirmation = "orderConfirmation";
  static const String payNow = "payNow";
  static const String orderNumber = "orderNumber";
  static const String orderDate = "orderDate";
  static const String totalAmount = "totalAmount";
  static const String shippingAddress = "shippingAddress";
  static const String contactNumber = "contactNumber";
  static const String proceedToPayment = "proceedToPayment";
  static const String shippingDetails = "shippingDetails";
  static const String contactInformation = "contactInformation";
  static const String mobileNumber = "mobileNumber";
  static const String mobileNumberRequired = "mobileNumberRequired";
  static const String address = "address";
  static const String addressRequired = "addressRequired";
  static const String cityRequired = "cityRequired";
  static const String country = "country";
  static const String countryRequired = "countryRequired";
  static const String continueToPayment = "continueToPayment";
  static const String itemDetails = "itemDetails";
  static const String itemDescription = "itemDescription";
  static const String weight = "weight";
  static const String waitingForPayment = "waitingForPayment";
  static const String alreadyPaid = "alreadyPaid";
  static const String or = "or";
  static const String notifications = "notifications";
  static const String buyNow = "buyNow";
  static const String itemNumber = "itemNumber";
  static const String auctionItems = "auctionItems";
  static const String auctionNumber = "auctionNumber";
  static const String startsAt = "startsAt";
  static const String endsAt = "endsAt";
  static const String countdownStartsIn = "countdownStartsIn";
  static const String currentItem = "currentItem";
  static const String auctionInformation = "auctionInformation";
  
  // ── Validation ─────────────────────────────────────────────────────────────
  
  static const String phoneRequired = "phoneRequired";
  static const String phoneInvalidInternational = "phoneInvalidInternational";
  static const String phoneInvalidKsa = "phoneInvalidKsa";
  static const String verifyOtp = "verifyOtp";
  static const String enterOtpForNumber = "enterOtpForNumber";
  static const String verify = "verify";
  static const String resendCode = "resendCode";
  static const String otpResentSuccessfully = "otpResentSuccessfully";
  static const String otpCodeExpiresIn = "otpCodeExpiresIn";
  static const String enter4DigitCode = "enter4DigitCode";
  static const String otpWillBeSentBySms = "otpWillBeSentBySms";
  static const String otpWillBeSentByWhatsapp = "otpWillBeSentByWhatsapp";
  static const String otpWillBeSentByWhatsappWithSmsFallback =
      "otpWillBeSentByWhatsappWithSmsFallback";
  static const String more = "more";
  static const String settings = "settings";
  static const String account = "account";
  static const String preferences = "preferences";
  static const String supportAndLegal = "supportAndLegal";
  static const String dangerZone = "dangerZone";
  static const String products = "products";
  static const String bidNow = "bidNow";
  static const String willStartSoon = "willStartSoon";
  static const String remainingTime = "remainingTime";
  static const String untilLive = "untilLive";
  static const String untilPreAuction = "untilPreAuction";
  static const String preAuctionStarted = "preAuctionStarted";
  static const String currency = "currency";
  static const String markAllAsRead = "markAllAsRead";
  static const String allNotificationsMarkedRead = "allNotificationsMarkedRead";
  static const String failedToMarkNotifications = "failedToMarkNotifications";
  static const String noNotifications = "noNotifications";
  static const String notificationsWillAppearHere = "notificationsWillAppearHere";
  static const String errorLoadingNotifications = "errorLoadingNotifications";
  static const String openLink = "openLink";

  // ── Notification Types ─────────────────────────────────────────────────────
  
  static const String notificationAuctionStarted = "notificationAuctionStarted";
  static const String notificationNewBid = "notificationNewBid";
  static const String notificationOutbid = "notificationOutbid";
  static const String notificationAuctionWon = "notificationAuctionWon";
  static const String notificationAuctionEndingSoon = "notificationAuctionEndingSoon";
  static const String notificationOrderStatus = "notificationOrderStatus";
  static const String notificationAuctionAccessApproved = "notificationAuctionAccessApproved";
  static const String notificationSpecialOffer = "notificationSpecialOffer";

  // ── Time Formatting ────────────────────────────────────────────────────────
  
  static const String daysAgo = "daysAgo";
  static const String yesterday = "yesterday";
  static const String hoursAgo = "hoursAgo";
  static const String minutesAgo = "minutesAgo";
  static const String justNow = "justNow";

  // ── Product Details ───────────────────────────────────────────────────────
  
  static const String productInfo = "productInfo";
  static const String basicData = "basicData";
  static const String productType = "productType";
  static const String material = "material";
  static const String approximateAge = "approximateAge";
  static const String productCondition = "productCondition";
  static const String origin = "origin";
  static const String orderPending = "orderPending";

  // ── Cart ───────────────────────────────────────────────────────────────────
  
  static const String cartEmpty = "cartEmpty";
  static const String checkout = "checkout";
  static const String signInRequired = "signInRequired";
  static const String signInToAddToCart = "signInToAddToCart";

  // ── Bidding Controls ───────────────────────────────────────────────────────
  
  static const String currentPrice = "currentPrice";
  static const String bidWith = "bidWith";
  static const String bidBy = "bidBy";
  static const String searchingForBidders = "searchingForBidders";
  static const String confirmBid = "confirmBid";
  static const String confirmBidMessage = "confirmBidMessage";
  static const String confirm = "confirm";
  static const String auctionEnded = "auctionEnded";
  static const String winner = 'winner';
  static const String finalPrice = 'finalPrice';
  static const String live = 'live';
  static const String public = "public";
  static const String auctionDetails = "auctionDetails";
  static const String notSpecified = "notSpecified";
  static const String usage = "usage";
  static const String youWon = 'youWon';
  static const String youLost = 'youLost';
  static const String sold = 'sold';
  static const String expired = 'expired';
  static const String noBidsYet = 'noBidsYet';
  static const String noResultsFound = 'noResultsFound';

  // ── Seller / Create Item ───────────────────────────────────────────────────
  
  static const String createAuction = 'createAuction';
  static const String createProduct = 'createProduct';
  static const String product = 'product';
  static const String auction = 'auction';
  static const String images = 'images';
  static const String title = 'title';
  static const String description = 'description';
  static const String startingPrice = 'startingPrice';
  static const String category = 'category';
  static const String brandOptional = 'brandOptional';
  static const String materialOptional = 'materialOptional';
  static const String conditionOptional = 'conditionOptional';
  static const String approximateAgeOptional = 'approximateAgeOptional';
  static const String required_ = 'required_';
  static const String pleaseSelectAtLeastOneImage = 'pleaseSelectAtLeastOneImage';
  static const String pleaseSelectCategory = 'pleaseSelectCategory';
  static const String itemCreatedSuccessfully = 'itemCreatedSuccessfully';
  static const String hostDashboard = 'hostDashboard';
  static const String myProducts = 'myProducts';
  static const String addNewItem = 'addNewItem';
  static const String noAuctionsCreatedYet = 'noAuctionsCreatedYet';
  static const String noProductsCreatedYet = 'noProductsCreatedYet';
  static const String upcoming = 'upcoming';
  static const String ended = 'ended';
  static const String startPrice = 'startPrice';
  static const String untitledAuction = 'untitledAuction';
  static const String untitledProduct = 'untitledProduct';
  static const String errorLoadingCategories = 'errorLoadingCategories';

  // ── Auction Details / Creation ───────────────────────────────────────────
  
  static const String actualPrice = 'actualPrice';
  static const String minBidPriceLabel = 'minBidPriceLabel';
  static const String bidIncrement = 'bidIncrement';
  static const String auctionQuantity = 'auctionQuantity';
  static const String expiryDate = 'expiryDate';
  static const String startDate = 'startDate';
  static const String auctionTypeLabel = 'auctionTypeLabel';
  static const String originOptional = 'originOptional';
  static const String usageOptional = 'usageOptional';
  static const String selectDate = 'selectDate';

  // ── Access & Permissions ──────────────────────────────────────────────────
  
  static const String youAreAuctionOwner = 'youAreAuctionOwner';
  static const String yourProduct = 'yourProduct';
  static const String likes = 'likes';
  static const String nextItem = 'nextItem';
  static const String welcomeBackMessage = 'welcomeBackMessage';
  static const String letsWinAuctions = 'letsWinAuctions';
  static const String createNewAccount = 'createNewAccount';

  // ── Filtering ─────────────────────────────────────────────────────────────
  
  static const String priceRange = 'priceRange';
  static const String minPriceLabel = 'minPriceLabel';
  static const String maxPriceLabel = 'maxPriceLabel';
  static const String condition = 'condition';
  static const String age = 'age';

  static const String lessThan10Years = 'lessThan10Years';
  static const String tenToFiftyYears = 'tenToFiftyYears';
  static const String plus50Years = 'plus50Years';
  static const String newCondition = 'newCondition';
  static const String usedCondition = 'usedCondition';
  static const String antiqueCondition = 'antiqueCondition';
  static const String dateRange = 'dateRange';
  static const String yearFrom = 'yearFrom';
  static const String yearTo = 'yearTo';
  static const String itemType = 'itemType';
  static const String denomination = 'denomination';
  static const String gradedStatus = 'gradedStatus';
  static const String graded = 'graded';
  static const String notGraded = 'notGraded';
  static const String gradingCompany = 'gradingCompany';
  static const String gradeDesignation = 'gradeDesignation';
  static const String gradeRange = 'gradeRange';
  static const String gradeFrom = 'gradeFrom';
  static const String gradeTo = 'gradeTo';
  static const String metalType_ = 'metalType_';
  static const String metalFineness = 'metalFineness';

  // ── Payments & Receipts ──────────────────────────────────────────────────
  
  static const String uploadReceipt = 'uploadReceipt';
  static const String selectFile = 'selectFile';
  static const String uploadingReceipt = 'uploadingReceipt';
  static const String receiptUploadedSuccessfully = 'receiptUploadedSuccessfully';
  static const String myPayments = 'myPayments';
  static const String paymentPending = 'paymentPending';
  static const String paymentApproved = 'paymentApproved';
  static const String paymentRejected = 'paymentRejected';
  static const String fileSizeExceeded = 'fileSizeExceeded';
  static const String selectImageOrPdf = 'selectImageOrPdf';
  static const String viewPayments = 'viewPayments';
  static const String noPaymentsYet = 'noPaymentsYet';
  static const String rejectionReason = 'rejectionReason';
  static const String uploadNewReceipt = 'uploadNewReceipt';
  static const String continueToOrder = 'continueToOrder';
  static const String paymentMethod = 'paymentMethod';
  static const String cardPayment = 'cardPayment';
  static const String bankTransfer = 'bankTransfer';
  static const String bankAccountInfo = 'bankAccountInfo';
  static const String orderSubmittedSuccessfully = 'orderSubmittedSuccessfully';
  static const String completeYourOrder = 'completeYourOrder';
  static const String viewReceipt = 'viewReceipt';
  static const String paymentSuccessful = 'paymentSuccessful';
  static const String paymentFailed = 'paymentFailed';
  static const String paymentVerificationPending =
      'paymentVerificationPending';
  static const String geideaSessionReady = 'geideaSessionReady';
  static const String geideaCheckoutComingSoon = 'geideaCheckoutComingSoon';
  static const String geideaCheckoutPreparing = 'geideaCheckoutPreparing';
  static const String geideaCheckoutCanceled = 'geideaCheckoutCanceled';
  static const String geideaSdkNotConfigured = 'geideaSdkNotConfigured';
  static const String geideaSaveCardNotSupported =
      'geideaSaveCardNotSupported';
  static const String savedPaymentMethods = 'savedPaymentMethods';
  static const String noSavedPaymentMethods = 'noSavedPaymentMethods';
  static const String addCard = 'addCard';
  static const String removeCard = 'removeCard';
  static const String saveCardForFutureUse = 'saveCardForFutureUse';
  static const String defaultCard = 'defaultCard';
  static const String cardSavedSuccessfully = 'cardSavedSuccessfully';
  static const String savedPaymentMethodsRefreshed =
      'savedPaymentMethodsRefreshed';

  // ── Order Tracking ────────────────────────────────────────────────────────
  
  static const String shipped = 'shipped';
  static const String delivered = 'delivered';
  static const String confirmed = 'confirmed';
  static const String orderStatusTimeline = 'orderStatusTimeline';
  static const String orderCreatedWaiting = 'orderCreatedWaiting';
  static const String receiptUploadedWaiting = 'receiptUploadedWaiting';
  static const String paymentVerifiedConfirmed = 'paymentVerifiedConfirmed';
  static const String itemOnItsWay = 'itemOnItsWay';
  static const String itemDeliveredSuccessfully = 'itemDeliveredSuccessfully';
  static const String checkOrder = 'checkOrder';
  static const String noItemsFound = 'noItemsFound';

  // ── Errors & Connectivity ─────────────────────────────────────────────────
  
  static const String noInternetConnection = 'noInternetConnection';
  static const String checkInternetConnection = 'checkInternetConnection';
  static const String orderNotAvailable = 'orderNotAvailable';
  static const String couldNotLoadOrders = 'couldNotLoadOrders';
  static const String couldNotLoadCart = 'couldNotLoadCart';
  static const String couldNotUpdateCart = 'couldNotUpdateCart';
  static const String couldNotUploadReceipt = 'couldNotUploadReceipt';
  static const String couldNotUpdateAddress = 'couldNotUpdateAddress';
  static const String couldNotStartPayment = 'couldNotStartPayment';
  static const String couldNotCheckPaymentStatus = 'couldNotCheckPaymentStatus';
  static const String couldNotLoadSavedCards = 'couldNotLoadSavedCards';
  static const String couldNotUpdateSavedCards = 'couldNotUpdateSavedCards';

  // ── Address Book ──────────────────────────────────────────────────────────
  
  static const String myAddresses = 'myAddresses';
  static const String addNewAddress = 'addNewAddress';
  static const String editAddress = 'editAddress';
  static const String deleteAddress = 'deleteAddress';
  static const String addressLabel = 'addressLabel';
  static const String recipientName = 'recipientName';
  static const String recipientMobile = 'recipientMobile';
  static const String setAsDefault = 'setAsDefault';
  static const String defaultAddress = 'defaultAddress';
  static const String noAddressesSaved = 'noAddressesSaved';
  static const String selectAddress = 'selectAddress';
  static const String changeAddress = 'changeAddress';
  static const String addressDeletedSuccessfully = 'addressDeletedSuccessfully';
  static const String addressSavedSuccessfully = 'addressSavedSuccessfully';
  static const String selectedAddress = 'selectedAddress';
  static const String selectItemToBid = 'selectItemToBid';

  // ── Access Control ────────────────────────────────────────────────────────
  
  static const String requestAccess = 'requestAccess';
  static const String requestAccessDescription = 'requestAccessDescription';
  static const String accessPending = 'accessPending';
  static const String accessDenied = 'accessDenied';
  static const String bidLimitExceeded = 'bidLimitExceeded';
  static const String myAuctionRequests = 'myAuctionRequests';
  static const String auctionAccessRequired = 'auctionAccessRequired';
  static const String accessGranted = 'accessGranted';

  // ── Real-time Bidding ─────────────────────────────────────────────────────
  
  static const String auctionBidNumber = 'auctionBidNumber';
  static const String highestBid = 'highestBid';
  static const String outbid = 'outbid';
  static const String currentAuction = 'currentAuction';
  static const String higherBidThanYours = 'higherBidThanYours';
  static const String bidPlacedSuccessfully = 'bidPlacedSuccessfully';
  static const String noRequestsFound = 'noRequestsFound';
  static const String filterOptions = 'filterOptions';
  static const String sortByPriceLowToHigh = 'sortByPriceLowToHigh';
  static const String sortByPriceHighToLow = 'sortByPriceHighToLow';
  static const String itemsIBiddedOn = 'itemsIBiddedOn';
  static const String defaultSort = 'defaultSort';
  static const String itemEndedSoldFor = 'itemEndedSoldFor';
  static const String comingSoon = 'comingSoon';
  static const String maxBid = 'maxBid';
  static const String oneStepBid = 'oneStepBid';
  static const String bid = 'bid';
  static const String priceUpdatedRetry = 'priceUpdatedRetry';

  // ── Localization Extensions ────────────────────────────────────────────────
  
  static const String shortAddressCode = 'shortAddressCode';
  static const String shortAddressHint = 'shortAddressHint';
  static const String invalidShortAddress = 'invalidShortAddress';
  static const String cityArea = 'cityArea';

  // ── Legal ──────────────────────────────────────────────────────────────────
  
  static const String terms1Title = "terms1Title";
  static const String terms1Content = "terms1Content";
  static const String terms2Title = "terms2Title";
  static const String terms2Content = "terms2Content";
  static const String terms3Title = "terms3Title";
  static const String terms3Content = "terms3Content";
  static const String terms4Title = "terms4Title";
  static const String terms4Content = "terms4Content";
  static const String terms5Title = "terms5Title";
  static const String terms5Content = "terms5Content";
  static const String terms6Title = "terms6Title";
  static const String terms6Content = "terms6Content";
  static const String terms7Title = "terms7Title";
  static const String terms7Content = "terms7Content";
  static const String terms8Title = "terms8Title";
  static const String terms8Content = "terms8Content";
  static const String terms9Title = "terms9Title";
  static const String terms9Content = "terms9Content";
  static const String terms10Title = "terms10Title";
  static const String terms10Content = "terms10Content";
  static const String terms11Title = "terms11Title";
  static const String terms11Content = "terms11Content";

  static const String privacy1Title = "privacy1Title";
  static const String privacy1Content = "privacy1Content";
  static const String privacy2Title = "privacy2Title";
  static const String privacy2Content = "privacy2Content";
  static const String privacy3Title = "privacy3Title";
  static const String privacy3Content = "privacy3Content";
  static const String privacy4Title = "privacy4Title";
  static const String privacy4Content = "privacy4Content";
  static const String privacy5Title = "privacy5Title";
  static const String privacy5Content = "privacy5Content";
  static const String privacy6Title = "privacy6Title";
  static const String privacy6Content = "privacy6Content";
  static const String privacy7Title = "privacy7Title";
  static const String privacy7Content = "privacy7Content";
  static const String privacy8Title = "privacy8Title";
  static const String privacy8Content = "privacy8Content";
  static const String privacy9Title = "privacy9Title";
  static const String privacy9Content = "privacy9Content";

  static const String whatsApp = "whatsApp";
  static const String call = "call";
}
