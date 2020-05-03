/*
 * This is the source code of iGap for iOS
 * It is licensed under GNU AGPL v3.0
 * You should have received a copy of the license in this archive (see LICENSE).
 * Copyright © 2017 , iGap - www.iGap.net
 * iGap Messenger | Free, Fast and Secure instant messaging application
 * The idea of the Kianiranian STDG - www.kianiranian.com
 * All rights reserved.
 */
import Foundation

enum IGStringsManager : String {
    
    //MARK: - Global Vars
    case Inventory = "Inventory"
    case GlobalConnecting = "connecting"
    case GlobalWaitingConnection = "waiting_for_network"
    case GlobalWarning = "error"
    case GlobalAttention = "attention"
    case GlobalAlerrt = "st_alert"
    case GlobalClose = "close"
    case GlobalCancel = "cancel"
    case GlobalOK = "dialog_ok"
    case GlobalDone = "dialog_done"
    case GlobalUpdating = "updating"
    case GlobalNo = "st_dialog_reset_all_notification_no"
    case GlobalYes = "st_dialog_reset_all_notification_yes"
    case GlobalNoNetwork = "connection_error"
    case GlobalNext = "next"
    case GlobalNew = "new_text"
    case GlobalSave = "save"
    case GlobalTimeOut = "time_out_error"
    case GlobalTryAgain = "str_frag_sync_error"
    case GlobalCommunicating = "communicating"
    case GlobalNoHistory = "not_exist_activities"
    case GlobalAppVersion = "app_version"
    case GlobalCheckUpdate = "check_update_title"
    case GlobalUpdateVersion = "updated_version_title"
    case GlobalUpdate = "igap_update"
    case iGap = "app_name"
    case SearchPlaceHolder = "Search"
    case GlobalCheckFields = "check_all_the_fields"
    case GlobalMinimumLetters = "minimum_number_of_letters"
    case GlobalLoading = "loading"
    case GlobalOKandGo = "ok_and_go"
    case GlobalMessage = "message"
    case GlobalSuccess = "kuknos_changePIN_successTitle"
    case ContactSending = "contacts_sending"
    case ContactSaving = "contacts_saving"
    case ContactDelete = "to_delete_contact"
    case Edit = "edit"
    case ViewContact = "view_contact"
    case TextCopied = "text_copied"
    case FetchingInfo = "fetching_info"
    
    //MARK: -NEWS
    case NewsDetail =  "news_details"
    //MARK: - VOTE
    case AlreadyVoted = "before_try"
    case MaximumPoll = "maximum_poll"
    case Chart = "chart"
    
    //MARK: - Charity
    case Charity = "charity_title"
    
    //MARK: - Nav Vars
    case NavLastSeenRecently = "last_seen_recently"
    case InAminute = "minute_ago"
    case MinuteAgo = "minutes_ago"
    case AnHourAgo = "an_hour_ago"
    case HoursAgo = "hours_ago"
    case Member = "member"
    case GlobalSkip = "ra_skip"
    case GlobalHint = "hint"
    case LastSeenAt = "last_seen_at"
    case LongTimeAgo = "long_time_ago"
    case LastMonth = "last_month"
    case Lastweak = "last_week"
    case Online = "online"
    case IgapSupport = "st_title_support"
    case NotificationServices = "service_notification"
    case AddFirstName = "please_enter_firstname_or_lastname"
    case SureToDeleteContact = "delete_text"
    case MuteNotification = "mute_notification"
    
    //MARK: - Intro Page
    case IntroTitleOne = "text_line_1_introduce_page3"
    case IntroTitleTwo = "text_line_1_introduce_page7"
    case IntroTitleThree = "text_line_1_introduce_page4"
    case IntroTitleFour = "text_line_1_introduce_page2"
    case IntroDescOne = "text_line_2_introduce_page3"
    case IntroDescTwo = "text_line_2_introduce_page7"
    case IntroDescThree = "text_line_2_introduce_page4"
    case IntroDescFour = "text_line_2_introduce_page2"
    
    //MARK: -Registration Process
    case RegisterationStepOneTitle = "rg_title_register"
    case PrivacyAgreement = "terms_and_condition"
    case PrivacyAgreementClickablePart = "terms_and_condition_clickable"
    case BtnSendCode = "rg_Start"
    case PickNumWithCountry = "rg_confirm_text_register"
    case ChooseCountry = "rg_Select_Country"
    case LoginWithQrScan = "register_with_barcode_scan"
    case LoginWithQrTitle = "register_with_barcode_scan_title"
    case YouHaveEnteredNumber = "Re_dialog_verify_number_part1"
    case ConfirmIfNumberIsOk = "Re_dialog_verify_number_part2"
    case dialogEdit = "edit_item_dialog"
    case VerifyMobile = "auth_verify_mobile"
    case Via = "via"
    case SMS = "verify_register_sms"
    case CALL = "call"
    case Email = "email"
    case AddContact = "fac_Add_Contact"
    case CallQuestion = "call_question"
    case AddContactsQuestion = "text_add_to_list_contact"
    case SmsAndIGap = "sms_and_igap"
    case VerifyCodeSentTo = "Re_Enter_Verify_Code_Please"
    case EnterValidVerification = "verify_invalid_code_message"
    case ResendCode = "resend_code"
    case YourProfile = "your_profile"
    case EnterNameAndPhoto = "pu_desc_profileUser"
    case SetRefferalNumberHint = "representer_code"
    case FirstName = "fac_First_Name"
    case LastName = "fac_Last_Name"
    case PhoneNumber = "fac_Phone_Number"
    case Information = "st_title_info"
    case Camera = "camera"
    case Gallery = "gallery"
    case TermsAndConditions = "terms_condition_title"
    case PrivacyPolicy = "privacy_policy"
    case ListOfBlockedUsers = "Block_Users"
    case BlockCard = "block_card"
    case UnblockUser = "un_block_user"
    case BlockUser = "block_user"
    case ProfilePhoto = "pu_addPhoto_profileUser"
    case LastSeen = "Last_Seen"
    case Groups = "Groups"
    case Channels = "Channels"
    case FetchingRooms = "fetching_rooms"
    case TwoSteps = "Two_Step_Verification"
    case ForgetPassword = "forgot_password"
    case TwoStepHeader = "two_step_verficatiion_header"
    case SecurityQuestion = "recovery_by_question_dialog"
    case PleaseEnterPassword = "please_enter_your_password"
    case LoginUsingQRTitle = "show_and_login_using_qr_title"
    case LoginUsingQr = "Login_with_QrCode"
    case SetReferral = "representer"
    case TwoStepVerificationHint = "msg_security_two_step_verification_hint"
    case SecurityQOne = "password_Question_title_one"
    case SecurityQTwo = "password_Question_title_two"
    case AnswerEmpty = "mpl_transaction_empty"
    
    //MARK: - Creat Room StoryBoard
    case ChannelInfo = "channel_info"
    case ShowMember = "show_member"
    case Username = "st_username"
    case Referral = "ra_title"
    case DeleteChannel = "channel_delete"
    case GroupName = "group_name"
    case GroupDesc = "group_description"
    case GroupNotExist = "group_not_exist"
    case ChannelNotExist = "channel_not_exist"
    case UserNotExist = "user_not_exist"
    case ChannelDesc = "channel_description"
    case PublicChannel = "public_channel"
    case PrivateChannel = "private_channel"
    case PrivateChannelDesc = "desc_private_channel"
    case PublicChannelDesc = "desc_public_channel"
    case ChannelLink = "channel_link"
    case NewGroup = "new_group"
    case DeletePhoto = "array_Delete_photo"
    case NewChannel = "new_channel"
    case ChannelName = "channel_name"
    case NewChat = "New_Chat"
    case NewCall = "new_call"
    case NewChannelHint = "new_channel_hint"
    case Desc = "desc"
    case CreateGroup = "New_Group"
    case CreateChannel = "New_Channel"
    case MsgEnterChannelName = "please_enter_channel_name"
    case RestrictionCreatRoom = "title_limit_Create_Group"
    case InvalidUserName = "E_330_2"
    case AlreadyTakenUserName = "already_taken_username"
    case NewChannelPublicFooterHint = "new_channels_rules"
    case NewChannelPrivateFooterHint = "new_channels_rules_private"
    case AddAdmin = "add_admin"
    case AddModerator = "add_moderator"
    case AddMember = "add_member"
    case AddMemberTo = "add_member_to"
    case AssignAdmin = "set_admin"
    case AssignModerator = "set_modereator"
    case Kick = "set_kick"
    case RemoveAdmin = "remove_admin"
    case RemoveModerator = "remove_moderator"
    case chooseMemberPlease = "please_choose_a_member"
    case AlreadyIsInTheMemberList = "existing_member"
    case AlreadyAreInTheMemberList = "existing_members"
    case AdminRights = "admin_rights";
    case WhatCanThisAdminDo = "what_can_this_admin_do";
    case EditRoomRights = "edit_room_rights";
    case RoomRights = "room_rights";
    case ModifyRoom = "modify_room";
    case PostMessage = "post_message";
    case EditMessage = "edit_message";
    case DeleteMessage = "delete_message";
    case PinMessage = "pin_message_1";
    case RemoveUser = "remove_user";
    case EditAdminRights = "edit_admin_rights";
    case EditMemberRights = "edit_member_rights";
    case ListAdmin = "list_admin";
    case MemberRights = "member_rights";
    case WhatCanThisMemberDo = "what_can_this_member_do";
    case SendText = "send_text";
    case SendMedia = "send_media";
    case SendGif = "send_gif";
    case SendSticker = "send_sticker";
    case SendLink = "send_link";
    case NotAllowSendMessage = "not_allow_send_message";
    
    //MARK: - Wallet
    case ServerDown = "E_9006"
    case Pay = "pay"
    case Cashout = "cash_out_paygear"
    case MyCards = "my_cards"
    case AmountNotValid = "amount_not_valid"
    case AmountToPay = "amount_to_pay"
    case TotalAmount = "total_amount"
    case DiscountAmount = "discount_amount"
    case Discount = "discount"
    case ClubCardBalance = "club_balance"
    case UserWalletBalance = "wallet_balance"
    case Wallet = "wallet_card"
    case BankCard = "card_bank"
    case PaidTo = "pay_to"
    case Amount = "amount_2"
    case AmountPlaceHolder = "amount"
    case MyQr = "my_qr"
    case MyQrToPayHint = "my_qr_hint"
    case Currency = "rials"
    case EnterRecieverCode = "enter_reciever_code"
    case EnterCode = "please_enter_code_for_verify"
    case QrCodeScanner = "qr_code_scanner"
    case ScanBarcode = "scan_barcode"
    case Of = "of"
    case YourScore = "your_point"
    case Rank = "rank"
    case QrNotRecognised = "qr_not_detected"
    case GiftIsUsedAlready = "gift_is_used"
    case Gift = "gift"
    case GetGift = "get_gifts"
    case StoreWalletBalance = "wallet_store_balance"
    case DriverWalletBalance = "driver_wallet_balance"
    case Store = "shopAccountType"
    case Driver = "taxiAccountType"
    case Other = "st_title_other"
    case Personal = "personalAccountType"
    case TransactionHistory = "transaction_history"
    case ScoreHistory = "order_history"
    case SetAsDefaultCard = "set_as_default_card"
    case DeleteCard = "delete_card"
    case AddNewCard = "add_new_card"
    case EnterChargePrice = "enter_cash_in_price"
    case WalletBalance = "paygear_balance"
    case CashablePrice = "cashable_balance"
    case ChargeWallet = "charge_paygear"
    case CardNumber = "card_number"
    case Month = "month"
    case Year = "year"
    case EnterYourCardNumber = "enter_your_card_number"
    case WalletSettings = "settings"
    case WalletPin = "paygear_card_pin"
    case ResetWalletPin = "Forgot_Passwords"
    case NewPass = "new_pass"
    case RepeatPassCode = "confirm_pass"
    case CurrentPassCode = "current_pass"
    case NewCodeSuccessSent = "new_otp_requested"
    case OTPCode = "otp_code"
    case PinCodeSuccessChange = "kuknos_changePIN_successM"
    case IncorrectInput = "ivnalid_data_provided"
    case RemainingAmount = "remaining_balance"
    case InvoiceNumber = "wallet_invoice"
    case PayIdentifier = "pay_id"
    case TransactionIdentifier = "payment_rrn_title"
    case DestinationCard = "destination_card"
    case DestinationCardNumber = "destination_card_number"
    case DestinationIban = "destination_sheba_number"
    case DestinationBank = "destination_bank"
    case ShowRecepiet = "show_receipt"
    case SuccessPayment = "success_payment"
    case PaymentPending = "payment_pending"
    case Reciever = "reciever_name"
    case TransactionType = "transaction_type"
    case PaymentStatus = "kuknos_send_dialogTitle"
    case DateTime = "date_time"
    case MoneyRefounded = "refound"
    case CashoutPending = "settled_pending"
    case Recieve = "kuknos_panelStr_recieve"
    case PaidWithWalletTo = "pay_with_raad_card_to"
    case BuyClubFrom = "purchase_club_plan_from"
    case ShareOfSales = "shares_of_sales"
    case EnterCashoutAmount = "enter_cash_out_price"
    case ImmidiateCashout = "immediate_cash_out"
    case NormalCashout = "normal_cash_out"
    case ToWallet = "to_wallet"
    case HowToGetIBAN = "how_to_get_sheba"
    case PlaceHolder16 = "card_16_digits"
    case PlaceHolder24 = "sheba_20_digits"
    case CashoutRequest = "cashout_request"
    case EnterWalletPin = "enter_wallet_password"
    case SuccessOperation = "success_operation"
    case LowWalletbalance = "balance_low"
    case EnterIbanNumber = "enter_your_sheba_number"
    case AmountIn = "amount_in"
    case AmountOut = "amount_out"
    case Wage = "wage"
    case AccountOwnerName = "crad_to_card_dest_name"
    case WalletRrnNumber = "WalletRrnNumber"
    case GiftCardReport = "gift_card_report"
    case GiftCardsUsable = "usable"
    case GiftCardsActivated = "activated"
    case GiftCardsPosted = "posted"
    case ActivateOrSendAsMessage = "activate_or_send_as_message"
    case GiftStickerSendToOther = "gift_sticker_send_to_other"
    case Activation = "activation"
    case GiftCardActivationNote = "active_gift_card_note"
    case ActivationSuccessful = "activatation_successful"
    case CardListIsEmpty = "card_list_is_empty"
    case GiftStickerCardInfoTitle = "gift_sticker_card_info_title"
    case ExpireDate = "expire_date"
    case CVV2 = "cvv2"
    case InternetPin2 = "internet_pin_2"
    case ClickForCopy = "click_for_copy_title"
    case NationalCodeInquiry = "national_code_inquiry"
    case EnterNationalCode = "enter_national_code"
    case NationalCodeInquiryError = "national_code_inquiry_error"
    case GiftCardSentNote = "gift_card_sent_note"
    case GiftCardAlreadyUsed = "gift_card_already_used"
    case GiftCardSendQuestion = "gift_card_send_question"
    
    //Elec Bill
    case ElecBillID = "elecBill_pay_billID"
    case ElecCustomerAdd = "elecBill_searchCell_CustomerAddress"
    case ElecCustomerName = "elecBill_searchCell_CustomerName"
    case WaitDataFetch = "please_wait_data_loading"
    case InvalidBill = "invalid_bill_message"
    case Details = "detail_title"
    case BillPrice = "elecBill_pay_billPrice"
    case BillPayDate = "elecBill_pay_billTime"
    case BillImage = "elecBill_pay_billImage"
    case BillAddMode = "elecBill_pay_billAddBillList"
    case BillEditMode = "elecBill_edit_Btn"
    case BillBranchingInfo = "elecBill_pay_billBranchInfo"
    case BillOperations = "elec_bill_operations"
    case BillInqueryAndPay = "elecBill_main_billTitle"
    case BillFindMode = "elecBill_search_billSearch"
    case MyBills = "elecBill_main_billMyList"
    case Inquiry = "inquiry"
    case FillForm = "elecBill_add_form"
    case CustomerMobNum = "elecBill_add_phone"
    case CustomerTelNum = "elec_provider_customer_tel"
    case CustomerPostalCode = "elec_bill_customer_postal_code"
    case CustomerZone = "elec_bill_customer_zone"
    case BillName = "elec_bill_name"
    case CompanyCode = "elec_provider_company_code"
    case CompanyName = "elec_provider_company_name"
    case BillCustomerType = "elec_provider_customer_type"
    case BillPhase = "elec_provider_bill_phase"
    case BillVoltage = "elec_provider_bill_voltage"
    case BillPower = "elec_provider_bill_power"
    case BillTarif = "elec_provider_bill_tarif"
    case BillDeviceSerial = "elecBill_search_billSerial"
    case CustomerDueDate = "elec_bill_customer_due_date"
    case CustomerDeviceLastRead = "elec_bill_device_last_read"
    case EnterSerialNum = "elec_bill_enter_device_serial"
    case SelectProviderCompany = "elec_bill_select_provider_company_list"

    //MARK: -Call
    case Outgoing = "outgoing"
    case Missed = "missed"
    case Incomming = "incoming"
    case Canceled = "canceled"
    case All = "all"
    case VoiceCall = "voice_calls"
    case VideoCall = "video_calls"
    case MissedCall = "miss"
    case UnAnsweredCall = "not_answer"
    case CanceledCall = "canceled_call"
    case MissedVoiceCall = "MISSED_VOICE_CALL"
    case MissedVideoCall = "MISSED_VIDEO_CALL"
    case DidNotResponseToVoiceCall = "did_not_respond_to_ur_voice_call"
    case DidNotResponseToVideoCall = "did_not_respond_to_ur_video_call"
    case WhoCanVoiceCall = "who_is_allowed_to_voice_call"
    case Connecting = "connecting_call"
    case Connected = "connected"
    case Disconnected = "disconnected"
    case Failed = "faild"
    case Reject = "reject"
    case Busy = "busy"
    case IncomingCall = "incoming_call"
    case Ringing = "ringing"
    case Dialing = "signaling"
    case Minutes = "minutes"
    
    //MARK: -Errors and MSGs
    case ErrorInvalidAnswer = "invalid_question_token"
    case ErrorUnverifiedEmail = "E_114"
    case ErrorInvalidPass = "invalid_password"
    case InvalidHint = "Hint_cant_the_same_password"
    case ErrorPassNotMatch = "Password_dose_not_match"
    case ErrorTalkingWithOther = "e_904_8"
    case ErrorUserInConversation = "e_904_9"
    case ErrorDialedNumIsNotActive = "e_904_7"
    case ErrorUserIsBlocked = "e_904_6"
    case ErrorAllowedNotToCommunicate = "e_906_1"
    case BillID13 = "elecBill_Entry_lengthError"
    case LessThan10000 = "elecBill_error_bellowMin"
    case PinNotMatch = "kuknos_SetPassConf_error"
    case GlobalErrorForm = "please_fill_form_data_correctly"
    case AmountIsNotEnough = "Kuknos_transaction_error7"
    case MSGForgetTerms = "accept_terms_and_condition_error_message"
    case MapDistanceMSG = "info_map"
    case SureToSubmit = "are_you_sure_request"
    case voteFirst = "msg_vote_to_see_barchart"
    case Join = "join"
    case SureToForward = "sure_to_forward"
    case SureToJoin = "do_you_want_to_join_to_this"
    case SureToDeleteAccount = "elecBill_deleteAccount_desc"
    case SureToRemoveChannel = "do_you_want_delete_this_channel"
    case SureToLeaveChannel = "do_you_want_leave_this_channel"
    case SureToRemoveGroup = "do_you_want_delete_this"
    case SureToLeaveGroup = "do_you_want_left_this"
    case SureToLogout = "logout_prompt"
    case SureToUnpin = "unpin_are_u_sure"
    case SureToPin = "pin_are_u_sure"
    case SureToKickOut = "do_you_want_to_kick_this_member"
    case SureToTerminateThis = "active_session_content"
    case SureToRemoveAdminRoleFrom = "do_you_want_to_set_admin_role_to_member"
    case SureToDeleteChat = "do_you_want_to_delet_this_chat"
    case SUreToClearChatHistory = "clear_this_chat"
    case SureToRemoveModeratorRoleFrom = "do_you_want_to_set_modereator_role_to_member"
    case MSGUpdateUserNameForbidden = "msg_update_username_forbidden"
    case ErrorUpdateUSernameAfter = "update_username_after"
    case ErrorGroupLinkNotEmpty = "group_link_can_not_be_empty"
    case MSGRoleHasChanges = "role_has_changes"
    case MSGAlreadyAsYourMember = "exist_member"
    case MSGWriteReportDesc = "msg_write_ur_report_description"
    case MSGNoAdmins = "not_exist_admin"
    case MSGNoModerators = "not_exist_moderator"
    case WriteUrReason = "please_write_your_reasons"

    //MARK: - Financial Services
    case MidTerm = "mid_term"
    case LastTerm = "last_term"
    case FinancialServices = "financial_services"
    case ChargeSimCard = "buy_charge"
    case PayBills = "pay_bills"
    case PayTraficTicket = "pay_bills_crime"
    case HamrahAvalBillsInquiry = "bills_inquiry_mci"
    case HomeBillsInquiry = "bills_inquiry_telecom"
    case Charge = "charge"
    case Prepaid = "prepaid"
    case InCash = "incash"
    case PayGateway = "paygateway"
    case Irancell = "irancell"
    case Rightel = "ritel"
    case MCI = "hamrahe_aval"
    case NormalCharge = "normal_charge"
    case AmazingCharge = "amazing"
    case WimaxCharge = "wimax_charging"
    case PerminantalySimcard = "permanently_charge"
    case PortedSubsEnable = "ported_subscriber_enable"
    case PortedSubsDisable = "ported_subscriber_disable"
    case ChooseOperator = "please_select_operator"
    case ChargePrice = "charge_amount"
    case ChooseChargeType = "charge_type_error_message"
    case ChargeType = "charge_type"

    //MARK: -Map
    case EnableNearby = "Visible_Status_title_dialog"
    case NearByMessage = "Visible_Status_text_dialog"
    case Satelite = "satellite_view"
    case Standard = "default_view"
    case YourStatus = "hint_gps"
    case NoStatus = "comment_no"
    case ManuallyUpdateMap = "nearby"
    case NearbyUsers = "list_user_map"
    case DisableNearbyVisibility = "map_registration"
    case ClearStatus = "Clear_Status"
    case MSGNearbyDisble = "Visible_Status_text_dialog_invisible"
    case MSGEnaleLocationService = "enable_location_service"
    case Nearby = "igap_nearby"
    case Around = "around"
    case Meter = "meter"

    //MARK: -Chat
    case Messages = "messages"
    case Hashtags = "hashtag"
    case ConvertToGroup = "chat_to_group"
    case ChannelReactionMessageFooter = "reaction_message_detail"
    case ChannelSignMessagesFooter = "sign_channel_message_description"
    case SignMessages = "sign_message_title"
    case ShowChannelReactions = "show_channel_vote"
    case IntrestingChannel = "popular_channel"
    case IgapNews = "news_mainTitle"
    case mostErgent = "news_ergent"
    case mostSeen = "news_MHits"
    case latestNews = "news_latest"
    case comments = "news_comment"
    case addComment = "news_add_comment_title"
    case noComments = "news_no_comment"
    case Draft = "txt_draft"
    case UnreadMessage = "unread_message"
    case DeletedMessage = "deleted_message"
    case ForwardedFrom = "forwarded_from"
    case ForwardedMessage = "forwarded_message"
    case WalletMessage = "wallet_message"
    case CardToCardMessage = "card_to_card_message"
    case PaymentMessage = "payment_message"
    case Payment = "payment"
    case TopupMessage = "topup_message"
    case TopupRequesterMobileNumber = "requester_mobile_number"
    case TopupReceiverMobileNumber = "receivers_mobile_number"
    case InstallLatestVersion = "install_latest_version"
    case BillMessage = "bill_message"
    case ChannelCreated = "channel_created"
    case GroupLink = "group_link"
    case RoomCreated = "room_created"
    case RoomCreatedByU = "room_created_by_u"
    case GroupCreated = "group_created"
    case KickedOut = "MEMBER_KICKED"
    case JoinedIgap = "USER_JOINED"
    case LeftIgap = "USER_DELETED"
    case By = "prefix"
    case Added = "MEMBER_ADDED"
    case LeftPage = "MEMBER_LEFT"
    case Group = "group"
    case Public = "public"
    case Private = "private"
    case GroupType = "group_type"
    case ChannelType = "channel_type"
    case Videos = "videos"
    case Images = "images"
    case Gifs = "gifs"
    case ClearDataUsage = "clear_data_usage"
    case AreYouSure = "are_you_sure"
    case SolidColors = "solid_colors"
    case Reset = "st_title_reset"
    case PaymentHistory = "payment_history"
    case Files = "files"
    case Voices = "voices"
    case Audios = "audios"
    case Links = "links"
    case Documents = "documents"
    case ConvertedToPublic = "ROOM_CONVERTED_TO_PUBLIC"
    case ConvertedToPrivate = "ROOM_CONVERTED_TO_PRIVATE"
    case JoinedByInvite = "MEMBER_JOINED_BY_INVITE_LINK"
    case YouCanNotJoin = "you_can_not_join_this_room"
    case DeletedRoom = "Room_Deleted_log"
    case DeleteGroup = "delete_group"
    case SomeOne = "someone"
    case RoomNotExist = "room_not_exist"
    case Today = "today"
    case Edited = "edited"
    case Yesterday = "yesterday"
    case AnotherRoom = "another_room"
    case Albums = "albums"
    case ChooseFrame = "choose_frame"
    case Clip = "crop_image_menu_crop"
    case Filter = "filter"
    case Processing = "processing"
    case Video = "am_video"
    case Trim = "st_trim"
    case ForwardPermissionError = "dialog_readonly_chat"
    case ErrorMAxSelect = "E_713_3"
    case ErrorDeletedMessage = "not_found_message"
    case LocationMessage = "location_message"
    case ContactMessage = "contact_message"
    case GifMessage = "gif_message"
    case ImageMessage = "image_message"
    case AudioMessage = "audio_message"
    case TextMessage = "text_message"
    case FileMessage = "file_message"
    case VideoMessage = "video_message"
    case VoiceMessage = "voice_message"
    case StickerMessage = "sticker_message"
    case InviteFriends = "Invite_Friends"
    case Sticker = "sticker"
    case Phone = "phone"
    case Contacts = "contacts"
    case Contact = "am_contact"
    case ClearHistory = "clear_history"
    case Pornography = "st_Pornography"
    case Report = "st_Report"
    case Spam = "st_Spam"
    case Violence = "st_Violence"
    case Abuse = "st_Abuse"
    case FakeAccount = "st_FakeAccount"
    case Reply = "replay"
    case Copy = "array_Copy"
    case Forward = "forward_item_dialog"
    case Share = "share_item_dialog"
    case UserReportedBefore = "E_10167"
    case ReportSent = "st_send_report"
    case Leave = "left"
    case Delete = "delete"
    case CLearCashe = "st_title_Clear_Cache"
    case WhatToDo = "what_do_u_want"
    case More = "more"
    case Send = "send"
    case WhatsUrComment = "news_write_comment"
    case successComment = "news_add_comment_successToast"
    case Pin = "pin_message"
    case UnPin = "unpin"
    case Mute = "mute"
    case UnMute = "unmute"
    case WhichTypeOfMessage = "which_type_of"
    case Cloud = "chat_with_yourself"
    case ChatBG = "st_chatBackground"
    case BtnSet = "set"
    case Add = "Add"
    case Shareto = "share_to"
    case SelectChat = "select_chat"
    case Bot = "bot"
    case HeyJoinIgap = "invitation_message"
    case AddSticker = "add_sticker"
    case MaxPinAlert = "max_pins_alert"
    
    //MARK: -Setting
    case Gender = "st_Gander"
    case IgapVer = "iGap_version"
    case Faq = "faq"
    case Credit = "credit"
    case WaitUntil = "Toast_time_wait"
    case EnterCodeHere = "enter_the_code_here"
    case changePass = "Change_password"
    case RemovePass = "remove_password"
    case ChangeHint = "Change_hint"
    case ChangeSecurityQ = "Change_question_recovery"
    case ChangeRecoEmail = "change_email_recovery"
    case VerifyEmail = "set_unconfirmed_email"
    case RecoverByEmail = "Recovery_with_email"
    case RecoverByQuestions = "Recovery_with_question"
    case SelectOneOfBelow = "kuknos_Entry_Message"
    case TwoStepPassHeader = "two_step_verification_description"
    case TwoStepPassFooter = "your_email_desc"
    case Required = "mandatory"
    case Optional = "optional"
    case Answer = "password_answer"
    case PasswordReEnter = "verify_password"
    case Password = "password"
    case SendMessageSoundAlert = "send_message_sound_alert"
    case MessageNotifications = "st_title_messageNotification"
    case KeepMediaFooter = "keep_media_footer"
    case KeepMedia = "keep_media"
    case DiskNetworkUsageHeader = "disk_and_network_usage"
    case ManageStorage = "manage_spacing"
    case TextSize = "st_title_message_textSize"
    case ChatSample = "chat_preview_sample"
    case ChatSample2 = "chat_preview_sample2"
    case ChangeLang = "change_language_title"
    case Logout = "logout"
    case ChatSettings = "chat_setting"
    case DataStorage = "data_storage"
    case NotificationAndSound = "ntg_title_toolbar"
    case PrivacyAndSecurity = "st_title_Privacy_Security"
    case Security = "Security"
    case Settings = "chi_title_setting"
    case Nobody = "no_body"
    case MyContacts = "my_contacts"
    case Everbody = "everybody"
    case InAppbrowser = "st_inApp_Browser"
    //Active Session
    case TerminateAllSessions = "active_session_all_title"
    case Terminate = "terminate"
    case TerminateAllExept = "terminate_all"
    case ActiveSessions = "Active_session"
    case CurrentSession = "current_session"
    case LastActiveAt = "last_active_at"
    case IOS = "ios"
    case MacOs = "mac_os"
    case Android = "android"
    case Linux = "linux"
    case Widnows = "windows"
    case BlackBerry = "plat_form_blackberry"
    case IP = "ip"
    case SessionCreateOn = "create_time"
    case Country = "country"
    case SelfDestruct = "self_destructs"
    case SelfDestructFooter = "desc_self_destroy"
    
    //cardToCard
    case CardToCardRequest = "cardToCardRequest"
    case CardToCard = "cardToCardBtnText"
    case GiftCard = "gift_card"
    case GiftCardSelected = "gift_card_selected"
    case GiftStickerBuy = "gift_sticker_title"
    case PaymentErrorMessage = "payment_error_message"
    case InquiryAndShopping = "inquiry_and_shopping"
    case NationalCode = "national_code"
    case MyReceivedGiftSticker = "my_recived_gift_sticker"
    case Buy = "buy"
    case Price = "price"
    //MARK: -Other
    case Female = "Female"
    case Male = "Male"
    case TopUp = "mpl_transaction_topup"
    case Sales = "mpl_transaction_sales"
    case Bills = "bills"
    case Voloume = "buy_internet_package_volume_type_title"
    case MobileNumber = "mobile_number"
    case ChooseTime = "Select_Time"
    case Time = "buy_internet_package_time_type_title"
    case PackageType = "buy_internet_package_type_title"
    case BuyInternetPackage = "buy_internet_package_title"
    case OnlyMCI = "mci_opreator_check"
    case WrongPhoneNUmber = "enter_mobile_correctly"
    case Update = "startUpdate"
    case Before = "before"
    case At = "at"
    case Byte = "c_byte"
    case KB = "c_KB"
    case MB = "c_MB"
    case GB = "c_GB"
    case TB = "c_TB"
    case NewVersionAvailable = "new_version_avilable"
    case DepricatedVersion = "deprecated"
    case Bio = "st_bio"
    case InvalidCode = "E_10183"
    case PassCodeLock = "two_step_pass_code"
    case IfAwayFor = "if_you_are_away_for"
    case NoDetail = "noDetail_textView"
    case AllMembers = "all_member"
    case Admin = "administrators_title"
    case Moderators = "moderators_title"
    case SharedMedia = "shared_media"
    case DeleteAccount = "elecBill_cell_deleteAccount"
    case Unknown = "unknown"
    case Tablet = "tablet"
    case Mobile = "mobile"
    case Desktop = "desktop"
    case MoreDetails = "see_details"
    case WhoCanInviteToChannel = "who_can_invite_you_to_channel_s"
    case WhoCanInviteToGroups = "who_can_invite_you_to_group_s"
    case LastSeenCheckBy = "title_Last_Seen"
    case ProfilePhotoCheck = "title_who_can_see_my_avatar"
    case AcceptTheTerms = "accept_the_terms"
    case YouJoined = "you_joined"
    case To = "wallet_to"
    case From = "from"
    case TraceNumber = "trace_number"
    case BillType = "bill_type"
    case BillId = "bill_id"
    case OrderId = "mpl_transaction_order_id"
    case TerminalId = "mpl_terminal_no"
    case OpenNow = "open_now"
    case PaymentMoneyTransfer = "PAYMENT_TRANSFER_MONEY"
    case WalletMoneyTransfer = "WALLET_TRANSFER_MONEY"
    case CardMoneyTransfer = "CARD_TRANSFER_MONEY"
    case RefrenceNum = "reference_code"
    case SourceBank = "source_bank"
    case Selected = "multi_video_selected_for_send"
    case Start = "start"
    case SlideToCancel = "slide_to_cancel_en"
    case LongPressToRecord = "long_press_to_record"
    case UnpinForMe = "unpin_for_me"
    case UnpinForAll = "unpin_for_all"
    case ContactPermission = "permission_contact"
    case Location = "permission_location"
    case File = "am_file"
    case PhotoOrVideo = "photo_or_video"
    case Document = "am_document"
    case Pic = "am_picture"
    case DeleteForMe = "delete_for_me"
    case DeleteForMeAnd = "delete_for_me_and"
    case SendAgain = "send_again"
    case UnknownMessage = "unknown_message"
    case You = "you"
    //MARK: -Player
    case UnknownArtist = "unknown_artist"
    case UnknownAudio = "unknown_audio"
    
    //MARK: -BANKS
    case BankParsian = "bank_parsian"
    case BankSaman = "bank_saman"
    case BankMellat = "bank_mellat"
    case BankPasargad = "bank_pasargad"
    case BankEqtesadNovin = "bank_eghtesad_novin"
    case BankKarafarin = "bank_karafarin"
    case BankSarmaye = "bank_sarmayeh"
    case BankMelli = "bank_melli"
    case BankSepah = "bank_sepah"
    case BankDey = "bank_dey"
    case BankTejarat = "bank_tejarat"
    case BankRefah = "bank_refah"
    case BankSaderat = "bank_saderat"
    case BankMaskan = "bank_maskan"
    case BankShahr = "bank_shahr"
    case BankSina = "bank_sina"
    case BankKeshavarzi = "bank_keshavarzi"
    case BankMarkazi = "bank_markazi"
    case BankGardeshgari = "bank_gardeshgari"
    case BankPost = "bank_post_bank"
    case BankAnsar = "bank_ansar"
    case BankIranzamin = "bank_iran_zamin"
    case BankAyandeh = "bank_ayandeh"
    case BankResalat = "bank_resalat"
    case BankToseeTaavon = "bank_tosee_taavon"
    case BankToseeSaderat = "bank_tosee_saderat"
    case BankHekmat = "bank_hekmat_iranian"
    case BankSanatMadan = "bank_sanato_madan"
    case BankQavamin = "bank_ghavamin"
    case BankMehrIran = "bank_mehr_iran"
    case BankMehrEqtesad = "bank_mehr_eghtesad"
    case BankKosar = "bank_etebari_kosar"
    case BankEtebariTosee = "bank_etebari_tosee"
    case BankMelal = "bank_etebari_asgarieh"
    case PaygearCard = "paygear_card"
    
    //Theme
    case ClassicTheme = "Theme_Classic_Text"
    case DayTheme = "Theme_Day_Text"
    case NightTheme = "Theme_Night_Text"
    case AppIcon = "Theme_Icon_Appp"
    
    case CreateNewContact = "create_new_contact"
    case PhoneNumbers = "phone_numbers"
    case Emails = "emails"
    case BuyWithScore = "buy_with_score"
    case PaymentSpentScore = "payment_spentScore"
    case PostedTo = "posted_to"
    case ReceivedFrom = "received_from"
    
    // Mobile Bank
    case MBNavTitle = "mb_nav_title"
    case Login = "login"
    case LoginDescription = "login_description"
    case UsernameMB = "username_mb"
    case PasswordMB = "password_mb"
    case ServerError = "server_error"
    case EmptyUsernameWarning = "empty_username_warning"
    case EmptyPasswordWarning = "empty_password_warning"
    case MyParsian = "my_parsian"
    case MBCategoryCards = "mb_category_cards"
    case MBCategoryAccounts = "mb_category_accounts"
    case MBCategoryServices = "mb_category_services"
    case ShebaNumber = "mb_sheba_number"
    case LoanNumber = "mb_loan_number"
    case BranchName = "mb_branch_name"
    case State = "mb_state"
    case StartDate = "mb_start_date"
    case EndDate = "mb_end_date"
    case RemainedLoanCount = "mb_remained_loan_count"
    case LoanCount = "mb_loan_count"
    case PersonalInfo = "mb_personal_info"
    case BankCode = "mb_bank_code"
    case CustomerCode = "mb_customer_code"
    case CustomerName = "mb_customer_name"
    case LoanInfo = "mb_loan_info"
    case Penalty = "mb_penalty"
    case MBDiscount = "mb_discount"
    case MaturedUnpaiedInfo = "mb_matured_unpaied_info"
    case MaturedUnpaiedCount = "mb_matured_unpaied_count"
    case MaturedUnpaiedAmount = "mb_matured_unpaied_amount"
    case PaiedInfo = "mb_paied_info"
    case PaiedCount = "mb_paid_count"
    case PaiedAmount = "mb_paied_amount"
    case UnpaiedInfo = "mb_unpaied_info"
    case UnpaiedCount = "mb_unpaid_count"
    case UnpaiedAmount = "mb_unpaied_amount"
    case LoanPayList = "mb_loans_list"
    case LoanPayState = "mb_loan_payment_state"
    case LoanPayAmount = "mb_loan_payment_amount"
    case LoanUnpaidAmount = "mb_loan_unpaied_amount"
    case LoanPenaltyAmount = "mb_loan_penalty_amount"
    case LoanPayDate = "mb_loan_payment_date"

}


