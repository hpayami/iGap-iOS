/*
 * This is the source code of iGap for iOS
 * It is licensed under GNU AGPL v3.0
 * You should have received a copy of the license in this archive (see LICENSE).
 * Copyright © 2017 , iGap - www.iGap.net
 * iGap Messenger | Free, Fast and Secure instant messaging application
 * The idea of the Kianiranian STDG - www.kianiranian.com
 * All rights reserved.
 */

import UIKit
import IGProtoBuff
import SwiftProtobuf
import RxSwift


let protoClassesLookupTable: [Int: (proto: ResponseMessage.Type, reponseHandler: IGRequest.Handler.Type)] = [
    //System: xx
    0: (IGPErrorResponse.self                           as ResponseMessage.Type,
        IGErrorRequest.Handler.self                     as IGRequest.Handler.Type),
    30001: (IGPConnectionSecuringResponse.self              as ResponseMessage.Type,
            IGConnectionSecuringRequest.Handler.self        as IGRequest.Handler.Type),
    30002: (IGPConnectionSymmetricKeyResponse.self          as ResponseMessage.Type,
            IGConnectionSymmetricKeyRequest.Handler.self    as IGRequest.Handler.Type),
    30003: (IGPHeartbeatResponse.self                       as ResponseMessage.Type,
            IGHeartBeatRequest.Handler.self                 as IGRequest.Handler.Type),
    
    //User: 301xx
    30100: (IGPUserRegisterResponse.self                    as ResponseMessage.Type,
            IGUserRegisterRequest.Handler.self              as IGRequest.Handler.Type),
    30101: (IGPUserVerifyResponse.self                      as ResponseMessage.Type,
            IGUserVerifyRequest.Handler.self                as IGRequest.Handler.Type),
    30102: (IGPUserLoginResponse.self                       as ResponseMessage.Type,
            IGUserLoginRequest.Handler.self                 as IGRequest.Handler.Type),
    30103: (IGPUserProfileSetEmailResponse.self             as ResponseMessage.Type,
            IGUserProfileSetEmailRequest.Handler.self       as IGRequest.Handler.Type),
    30104: (IGPUserProfileSetGenderResponse.self            as ResponseMessage.Type,
            IGUserProfileSetGenderRequest.Handler.self      as IGRequest.Handler.Type),
    30105: (IGPUserProfileSetNicknameResponse.self          as ResponseMessage.Type,
            IGUserProfileSetNicknameRequest.Handler.self    as IGRequest.Handler.Type),
    30106: (IGPUserContactsImportResponse.self              as ResponseMessage.Type,
            IGUserContactsImportRequest.Handler.self        as IGRequest.Handler.Type),
    30107: (IGPUserContactsGetListResponse.self             as ResponseMessage.Type,
            IGUserContactsGetListRequest.Handler.self       as IGRequest.Handler.Type),
    30108: (IGPUserContactsDeleteResponse.self              as ResponseMessage.Type,
            IGUserContactsDeleteRequest.Handler.self        as IGRequest.Handler.Type),
    30109: (IGPUserContactsEditResponse.self                as ResponseMessage.Type,
            IGUserContactsEditRequest.Handler.self          as IGRequest.Handler.Type),
    30110: (IGPUserProfileGetEmailResponse.self             as ResponseMessage.Type,
            IGUserProfileGetEmailRequest.Handler.self       as IGRequest.Handler.Type),
    30111: (IGPUserProfileGetGenderResponse.self            as ResponseMessage.Type,
            IGUserProfileGetGenderRequest.Handler.self      as IGRequest.Handler.Type),
    30112: (IGPUserProfileGetNicknameResponse.self          as ResponseMessage.Type,
            IGUserProfileGetNicknameRequest.Handler.self    as IGRequest.Handler.Type),
    30114: (IGPUserAvatarAddResponse.self                   as ResponseMessage.Type,
            IGUserAvatarAddRequest.Handler.self             as IGRequest.Handler.Type),
    30115: (IGPUserAvatarDeleteResponse.self                as ResponseMessage.Type,
            IGUserAvatarDeleteRequest.Handler.self          as IGRequest.Handler.Type),
    30116: (IGPUserAvatarGetListResponse.self               as ResponseMessage.Type,
            IGUserAvatarGetListRequest.Handler.self         as IGRequest.Handler.Type),
    30117: (IGPUserInfoResponse.self                        as ResponseMessage.Type,
            IGUserInfoRequest.Handler.self                  as IGRequest.Handler.Type),
    30118: (IGPUserGetDeleteTokenResponse.self              as ResponseMessage.Type,
            IGUserGetDeleteTokenRequest.Handler.self        as IGRequest.Handler.Type),
    30119: (IGPUserDeleteResponse.self                      as ResponseMessage.Type,
            IGUserDeleteRequest.Handler.self                as IGRequest.Handler.Type),
    30120: (IGPUserProfileSetSelfRemoveResponse.self        as ResponseMessage.Type,
            IGUserProfileSetSelfRemoveRequest.Handler.self  as IGRequest.Handler.Type),
    30121: (IGPUserProfileGetSelfRemoveResponse.self        as ResponseMessage.Type,
            IGUserProfileGetSelfRemoveRequest.Handler.self  as IGRequest.Handler.Type),
    30122: (IGPUserProfileCheckUsernameResponse.self        as ResponseMessage.Type,
            IGUserProfileCheckUsernameRequest.Handler.self  as IGRequest.Handler.Type),
    30123: (IGPUserProfileUpdateUsernameResponse.self       as ResponseMessage.Type,
            IGUserProfileUpdateUsernameRequest.Handler.self as IGRequest.Handler.Type),
    30124: (IGPUserUpdateStatusResponse.self                as ResponseMessage.Type,
            IGUserUpdateStatusRequest.Handler.self          as IGRequest.Handler.Type),
    30125: (IGPUserSessionGetActiveListResponse.self        as ResponseMessage.Type,
            IGUserSessionGetActiveListRequest.Handler.self  as IGRequest.Handler.Type),
    30126: (IGPUserSessionTerminateResponse.self            as ResponseMessage.Type,
            IGUserSessionTerminateRequest.Handler.self      as IGRequest.Handler.Type),
    30127: (IGPUserSessionLogoutResponse.self               as ResponseMessage.Type,
            IGUserSessionLogoutRequest.Handler.self         as IGRequest.Handler.Type),
    30128: (IGPUserContactsBlockResponse.self               as ResponseMessage.Type,
            IGUserContactsBlockRequest.Handler.self         as IGRequest.Handler.Type),
    30129: (IGPUserContactsUnblockResponse.self             as ResponseMessage.Type,
            IGUserContactsUnBlockRequest.Handler.self       as IGRequest.Handler.Type),
    30130: (IGPUserContactsGetBlockedListResponse.self      as ResponseMessage.Type,
            IGUserContactsGetBlockedListRequest.Handler.self                        as IGRequest.Handler.Type),
    30131: (IGPUserTwoStepVerificationGetPasswordDetailResponse.self                as ResponseMessage.Type,
            IGUserTwoStepVerificationGetPasswordDetailRequest.Handler.self          as IGRequest.Handler.Type),
    30132: (IGPUserTwoStepVerificationVerifyPasswordResponse.self                   as ResponseMessage.Type,
            IGUserTwoStepVerificationVerifyPasswordRequest.Handler.self             as IGRequest.Handler.Type),
    30133: (IGPUserTwoStepVerificationSetPasswordResponse.self                      as ResponseMessage.Type,
            IGUserTwoStepVerificationSetPasswordRequest.Handler.self                as IGRequest.Handler.Type),
    30134: (IGPUserTwoStepVerificationUnsetPasswordResponse.self                    as ResponseMessage.Type,
            IGUserTwoStepVerificationUnsetPasswordRequest.Handler.self              as IGRequest.Handler.Type),
    30135: (IGPUserTwoStepVerificationCheckPasswordResponse.self                    as ResponseMessage.Type,
            IGUserTwoStepVerificationCheckPasswordRequest.Handler.self              as IGRequest.Handler.Type),
    30136: (IGPUserTwoStepVerificationVerifyRecoveryEmailResponse.self              as ResponseMessage.Type,
            IGUserTwoStepVerificationVerifyRecoveryEmailRequest.Handler.self        as IGRequest.Handler.Type),
    30137: (IGPUserTwoStepVerificationChangeRecoveryEmailResponse.self              as ResponseMessage.Type,
            IGUserTwoStepVerificationChangeRecoveryEmailRequest.Handler.self        as IGRequest.Handler.Type),
    30138: (IGPUserTwoStepVerificationRequestRecoveryTokenResponse.self             as ResponseMessage.Type,
            IGUserTwoStepVerificationRequestRecoveryTokenRequest.Handler.self       as IGRequest.Handler.Type),
    30139: (IGPUserTwoStepVerificationRecoverPasswordByTokenResponse.self           as ResponseMessage.Type,
            IGUserTwoStepVerificationRecoverPasswordByTokenRequest.Handler.self     as IGRequest.Handler.Type),
    30140: (IGPUserTwoStepVerificationRecoverPasswordByAnswersResponse.self         as ResponseMessage.Type,
            IGUserTwoStepVerificationRecoverPasswordByAnswersRequest.Handler.self   as IGRequest.Handler.Type),
    30141: (IGPUserTwoStepVerificationChangeRecoveryQuestionResponse.self           as ResponseMessage.Type,
            IGUserTwoStepVerificationChangeRecoveryQuestionRequest.Handler.self     as IGRequest.Handler.Type),
    30142: (IGPUserTwoStepVerificationChangeHintResponse.self                       as ResponseMessage.Type,
            IGUserTwoStepVerificationChangehintRequest.Handler.self                 as IGRequest.Handler.Type),
    30146: (IGPUserTwoStepVerificationResendVerifyEmailResponse.self                as ResponseMessage.Type,
            IGUserTwoStepVerificationResendVerifyEmailRequest.Handler.self          as IGRequest.Handler.Type),
    30143: (IGPUserPrivacyGetRuleResponse.self                                      as ResponseMessage.Type,
            IGUserPrivacyGetRuleRequest.Handler.self                                as IGRequest.Handler.Type),
    30144: (IGPUserPrivacySetRuleResponse.self                                      as ResponseMessage.Type,
            IGUserPrivacySetRuleRequest.Handler.self                                as IGRequest.Handler.Type),
    30145: (IGPUserVerifyNewDeviceResponse.self                                     as ResponseMessage.Type,
            IGUserVerifyNewDeviceRequest.Handler.self                               as IGRequest.Handler.Type),
    30147: (IGPUserProfileSetBioResponse.self                                       as ResponseMessage.Type,
            IGUserProfileSetBioRequest.Handler.self                                 as IGRequest.Handler.Type),
    30148: (IGPUserProfileGetBioResponse.self                                       as ResponseMessage.Type,
            IGUserProfileGetBioRequest.Handler.self                                 as IGRequest.Handler.Type),
    30149: (IGPUserReportResponse.self                                              as ResponseMessage.Type,
            IGUserReportRequest.Handler.self                                        as IGRequest.Handler.Type),
    30151: (IGPUserProfileGetRepresentativeResponse.self                            as ResponseMessage.Type,
            IGUserProfileGetRepresentativeRequest.Handler.self                      as IGRequest.Handler.Type),
    30152: (IGPUserProfileSetRepresentativeResponse.self                            as ResponseMessage.Type,
            IGUserProfileSetRepresentativeRequest.Handler.self                      as IGRequest.Handler.Type),
    30153: (IGPUserIVandGetActivitiesResponse.self                                  as ResponseMessage.Type,
            IGUserIVandGetActivitiesRequest.Handler.self                            as IGRequest.Handler.Type),
    30154: (IGPUserIVandGetScoreResponse.self                                       as ResponseMessage.Type,
            IGUserIVandGetScoreRequest.Handler.self                                 as IGRequest.Handler.Type),
    30155: (IGPUserIVandSetActivityResponse.self                                    as ResponseMessage.Type,
            IGUserIVandSetActivityRequest.Handler.self                              as IGRequest.Handler.Type),
    30156: (IGPUserRefreshTokenResponse.self                                        as ResponseMessage.Type,
            IGUserRefreshTokenRequest.Handler.self                                  as IGRequest.Handler.Type),
    
    //Chat: 302xx
    30200: (IGPChatGetRoomResponse.self                     as ResponseMessage.Type,
            IGChatGetRoomRequest.Handler.self               as IGRequest.Handler.Type),
    30201: (IGPChatSendMessageResponse.self                 as ResponseMessage.Type,
            IGChatSendMessageRequest.Handler.self           as IGRequest.Handler.Type),
    30202: (IGPChatUpdateStatusResponse.self                as ResponseMessage.Type,
            IGChatUpdateStatusRequest.Handler.self          as IGRequest.Handler.Type),
    30203: (IGPChatEditMessageResponse.self                 as ResponseMessage.Type,
            IGChatEditMessageRequest.Handler.self          as IGRequest.Handler.Type),
    30204: (IGPChatDeleteMessageResponse.self               as ResponseMessage.Type,
            IGChatDeleteMessageRequest.Handler.self        as IGRequest.Handler.Type),
    30205: (IGPChatClearMessageResponse.self                as ResponseMessage.Type,
            IGChatClearMessageRequest.Handler.self          as IGRequest.Handler.Type),
    30206: (IGPChatDeleteResponse.self                      as ResponseMessage.Type,
            IGChatDeleteRequest.Handler.self                as IGRequest.Handler.Type),
    30207: (IGPChatUpdateDraftResponse.self                 as ResponseMessage.Type,
            IGChatUpdateDraftRequest.Handler.self           as IGRequest.Handler.Type),
    30208: (IGPChatGetDraftResponse.self                    as ResponseMessage.Type,
            IGChatGetDraftRequest.Handler.self              as IGRequest.Handler.Type),
    30209: (IGPChatConvertToGroupResponse.self              as ResponseMessage.Type,
            IGChatConvertToGroupRequest.Handler.self        as IGRequest.Handler.Type),
    30210: (IGPChatSetActionResponse.self                   as ResponseMessage.Type,
            IGChatSetActionRequest.Handler.self            as IGRequest.Handler.Type),
    
    //Group: 303xx
    30300: (IGPGroupCreateResponse.self                     as ResponseMessage.Type,
            IGGroupCreateRequest.Handler.self               as IGRequest.Handler.Type),
    30301: (IGPGroupAddMemberResponse.self                  as ResponseMessage.Type,
            IGGroupAddMemberRequest.Handler.self            as IGRequest.Handler.Type),
    30302: (IGPGroupAddAdminResponse.self                   as ResponseMessage.Type,
            IGGroupAddAdminRequest.Handler.self             as IGRequest.Handler.Type),
    30303: (IGPGroupAddModeratorResponse.self               as ResponseMessage.Type,
            IGGroupAddModeratorRequest.Handler.self         as IGRequest.Handler.Type),
    30304: (IGPGroupClearMessageResponse.self               as ResponseMessage.Type,
            IGGroupClearMessageRequest.Handler.self         as IGRequest.Handler.Type),
    30305: (IGPGroupEditResponse.self                       as ResponseMessage.Type,
            IGGroupEditRequest.Handler.self                 as IGRequest.Handler.Type),
    30306: (IGPGroupKickAdminResponse.self                  as ResponseMessage.Type,
            IGGroupKickAdminRequest.Handler.self            as IGRequest.Handler.Type),
    30307: (IGPGroupKickMemberResponse.self                 as ResponseMessage.Type,
            IGGroupKickMemberRequest.Handler.self           as IGRequest.Handler.Type),
    30308: (IGPGroupKickModeratorResponse.self              as ResponseMessage.Type,
            IGGroupKickModeratorRequest.Handler.self        as IGRequest.Handler.Type),
    30309: (IGPGroupLeftResponse.self                       as ResponseMessage.Type,
            IGGroupLeftRequest.Handler.self                 as IGRequest.Handler.Type),
    30310: (IGPGroupSendMessageResponse.self                as ResponseMessage.Type,
            IGGroupSendMessageRequest.Handler.self          as IGRequest.Handler.Type),
    30311: (IGPGroupUpdateStatusResponse.self               as ResponseMessage.Type,
            IGGroupUpdateStatusRequest.Handler.self         as IGRequest.Handler.Type),
    30312: (IGPGroupAvatarAddResponse.self                  as ResponseMessage.Type,
            IGGroupAvatarAddRequest.Handler.self            as IGRequest.Handler.Type),
    30313: (IGPGroupAvatarDeleteResponse.self               as ResponseMessage.Type,
            IGGroupAvatarDeleteRequest.Handler.self         as IGRequest.Handler.Type),
    30314: (IGPGroupAvatarGetListResponse.self              as ResponseMessage.Type,
            IGGroupAvatarGetListRequest.Handler.self        as IGRequest.Handler.Type),
    30315: (IGPGroupUpdateDraftResponse.self                as ResponseMessage.Type,
            IGGroupUpdateDraftRequest.Handler.self          as IGRequest.Handler.Type),
    30316: (IGPGroupGetDraftResponse.self                   as ResponseMessage.Type,
            IGGroupGetDraftRequest.Handler.self             as IGRequest.Handler.Type),
    30317: (IGPGroupGetMemberListResponse.self              as ResponseMessage.Type,
            IGGroupGetMemberListRequest.Handler.self        as IGRequest.Handler.Type),
    30318: (IGPGroupDeleteResponse.self                     as ResponseMessage.Type,
            IGGroupDeleteRequest.Handler.self               as IGRequest.Handler.Type),
    30319: (IGPGroupSetActionResponse.self                  as ResponseMessage.Type,
            IGGroupSetActionRequest.Handler.self            as IGRequest.Handler.Type),
    30320: (IGPGroupDeleteMessageResponse.self              as ResponseMessage.Type,
            IGGroupDeleteMessageRequest.Handler.self        as IGRequest.Handler.Type),
    30321: (IGPGroupCheckUsernameResponse.self              as ResponseMessage.Type,
            IGGroupCheckUsernameRequest.Handler.self        as IGRequest.Handler.Type),
    30322: (IGPGroupUpdateUsernameResponse.self                as ResponseMessage.Type,
            IGGroupUpdateUsernameRequest.Handler.self       as IGRequest.Handler.Type),
    30323: (IGPGroupRemoveUsernameResponse.self             as ResponseMessage.Type,
            IGGroupRemoveUsernameRequest.Handler.self       as IGRequest.Handler.Type),
    30324: (IGPGroupRevokeLinkResponse.self                 as ResponseMessage.Type,
            IGGroupRevokLinkRequest.Handler.self            as IGRequest.Handler.Type),
    30325: (IGPGroupEditMessageResponse.self                as ResponseMessage.Type,
            IGGroupEditMessageRequest.Handler.self          as IGRequest.Handler.Type),
    30326: (IGPGroupPinMessageResponse.self                 as ResponseMessage.Type,
            IGGroupPinMessageRequest.Handler.self           as IGRequest.Handler.Type),
    30327: (IGPGroupChangeMemberRightsResponse.self         as ResponseMessage.Type,
            IGGroupChangeMemberRightsRequest.Handler.self   as IGRequest.Handler.Type),
    
    //Channel: 304xx
    30400: (IGPChannelCreateResponse.self                   as ResponseMessage.Type,
            IGChannelCreateRequest.Handler.self             as IGRequest.Handler.Type),
    30401: (IGPChannelAddMemberResponse.self                as ResponseMessage.Type,
            IGChannelAddMemberRequest.Handler.self          as IGRequest.Handler.Type),
    30402: (IGPChannelAddAdminResponse.self                 as ResponseMessage.Type,
            IGChannelAddAdminRequest.Handler.self           as IGRequest.Handler.Type),
    30403: (IGPChannelAddModeratorResponse.self             as ResponseMessage.Type,
            IGChannelAddModeratorRequest.Handler.self       as IGRequest.Handler.Type),
    30404: (IGPChannelDeleteResponse.self                   as ResponseMessage.Type,
            IGChannelDeleteRequest.Handler.self             as IGRequest.Handler.Type),
    30405: (IGPChannelEditResponse.self                     as ResponseMessage.Type,
            IGChannelEditRequest.Handler.self               as IGRequest.Handler.Type),
    30406: (IGPChannelKickAdminResponse.self                as ResponseMessage.Type,
            IGChannelKickAdminRequest.Handler.self          as IGRequest.Handler.Type),
    30407: (IGPChannelKickMemberResponse.self               as ResponseMessage.Type,
            IGChannelKickMemberRequest.Handler.self         as IGRequest.Handler.Type),
    30408: (IGPChannelKickModeratorResponse.self            as ResponseMessage.Type,
            IGChannelKickModeratorRequest.Handler.self      as IGRequest.Handler.Type),
    30409: (IGPChannelLeftResponse.self                     as ResponseMessage.Type,
            IGChannelLeftRequest.Handler.self               as IGRequest.Handler.Type),
    30410: (IGPChannelSendMessageResponse.self              as ResponseMessage.Type,
            IGChannelSendMessageRequest.Handler.self        as IGRequest.Handler.Type),
    30411: (IGPChannelDeleteMessageResponse.self            as ResponseMessage.Type,
            IGChannelDeleteMessageRequest.Handler.self      as IGRequest.Handler.Type),
    30412: (IGPChannelAvatarAddResponse.self                as ResponseMessage.Type,
            IGChannelAddAvatarRequest.Handler.self          as IGRequest.Handler.Type),
    30413: (IGPChannelAvatarDeleteResponse.self             as ResponseMessage.Type,
            IGChannelAvatarDeleteRequest.Handler.self       as IGRequest.Handler.Type),
    30414: (IGPChannelAvatarGetListResponse.self            as ResponseMessage.Type,
            IGChannelAvatarGetListRequest.Handler.self      as IGRequest.Handler.Type),
    30415: (IGPChannelUpdateDraftResponse.self              as ResponseMessage.Type,
            IGChannelUpdateDraftRequest.Handler.self        as IGRequest.Handler.Type),
    30416: (IGPChannelGetDraftResponse.self                 as ResponseMessage.Type,
            IGChannelGetDraftRequest.Handler.self           as IGRequest.Handler.Type),
    30417: (IGPChannelGetMemberListResponse.self            as ResponseMessage.Type,
            IGChannelGetMemberListRequest.Handler.self      as IGRequest.Handler.Type),
    30418: (IGPChannelCheckUsernameResponse.self            as ResponseMessage.Type,
            IGChannelCheckUsernameRequest.Handler.self      as IGRequest.Handler.Type),
    30419: (IGPChannelUpdateUsernameResponse.self           as ResponseMessage.Type,
            IGChannelUpdateUsernameRequest.Handler.self     as IGRequest.Handler.Type),
    30420: (IGPChannelRemoveUsernameResponse.self           as ResponseMessage.Type,
            IGChannelRemoveUsernameRequest.Handler.self     as IGRequest.Handler.Type),
    30421: (IGPChannelRevokeLinkResponse.self               as ResponseMessage.Type,
            IGChannelRevokeLinkRequest.Handler.self          as IGRequest.Handler.Type),
    30422: (IGPChannelUpdateSignatureResponse.self           as ResponseMessage.Type,
            IGChannelUpdateSignatureRequest.Handler.self     as IGRequest.Handler.Type),
    30423: (IGPChannelGetMessagesStatsResponse.self          as ResponseMessage.Type,
            IGChannelGetMessagesStatsRequest.Handler.self    as IGRequest.Handler.Type),
    30424: (IGPChannelAddMessageReactionResponse.self        as ResponseMessage.Type,
            IGChannelAddMessageReactionRequest.Handler.self  as IGRequest.Handler.Type),
    30425: (IGPChannelEditMessageResponse.self               as ResponseMessage.Type,
            IGChannelEditMessageRequest.Handler.self         as IGRequest.Handler.Type),
    30426: (IGPChannelUpdateReactionStatusResponse.self       as ResponseMessage.Type,
            IGChannelUpdateReactionStatusRequest.Handler.self as IGRequest.Handler.Type),
    30427: (IGPChannelPinMessageResponse.self                as ResponseMessage.Type,
            IGChannelPinMessageRequest.Handler.self          as IGRequest.Handler.Type),
    
    //Info: 305xx
    30500: (IGPInfoLocationResponse.self                    as ResponseMessage.Type,
            IGInfoLocationRequest.Handler.self              as IGRequest.Handler.Type),
    30501: (IGPInfoCountryResponse.self                     as ResponseMessage.Type,
            IGInfoCountryRequest.Handler.self               as IGRequest.Handler.Type),
    30503: (IGPInfoPageResponse.self                        as ResponseMessage.Type,
            IGInfoPageRequest.Handler.self                  as IGRequest.Handler.Type),
    30504: (IGPInfoWallpaperResponse.self                   as ResponseMessage.Type,
            IGInfoWallpaperRequest.Handler.self             as IGRequest.Handler.Type),
    30505: (IGPInfoUpdateResponse.self                     as ResponseMessage.Type,
            IGInfoUpdateResponse.Handler.self              as IGRequest.Handler.Type),
    
    //Client: 306xx
    30600: (IGPClientConditionResponse.self                 as ResponseMessage.Type,
            IGClientConditionRequest.Handler.self           as IGRequest.Handler.Type),
    30601: (IGPClientGetRoomListResponse.self               as ResponseMessage.Type,
            IGClientGetRoomListRequest.Handler.self         as IGRequest.Handler.Type),
    30602: (IGPClientGetRoomResponse.self                   as ResponseMessage.Type,
            IGClientGetRoomRequest.Handler.self             as IGRequest.Handler.Type),
    30603: (IGPClientGetRoomHistoryResponse.self            as ResponseMessage.Type,
            IGClientGetRoomHistoryRequest.Handler.self      as IGRequest.Handler.Type),
    30604: (IGPClientGetRoomMessageResponse.self            as ResponseMessage.Type,
            IGClientGetRoomMessageRequest.Handler.self      as IGRequest.Handler.Type),
    30605: (IGPClientSearchRoomHistoryResponse.self         as ResponseMessage.Type,
            IGClientSearchRoomHistoryRequest.Handler.self   as IGRequest.Handler.Type),
    30606: (IGPClientResolveUsernameResponse.self           as ResponseMessage.Type,
            IGClientResolveUsernameRequest.Handler.self     as IGRequest.Handler.Type),
    30607: (IGPClientCheckInviteLinkResponse.self           as ResponseMessage.Type,
            IGClinetCheckInviteLinkRequest.Handler.self     as IGRequest.Handler.Type),
    30608: (IGPClientJoinByInviteLinkResponse.self          as ResponseMessage.Type,
            IGClientJoinByInviteLinkRequest.Handler.self    as IGRequest.Handler.Type),
    30609: (IGPClientJoinByUsernameResponse.self            as ResponseMessage.Type,
            IGClientJoinByUsernameRequest.Handler.self      as IGRequest.Handler.Type),
    30610: (IGPClientSubscribeToRoomResponse.self           as ResponseMessage.Type,
            IGClientSubscribeToRoomRequest.Handler.self     as IGRequest.Handler.Type),
    30611: (IGPClientUnsubscribeFromRoomResponse.self       as ResponseMessage.Type,
            IGClientUnsubscribeFromRoomRequest.Handler.self as IGRequest.Handler.Type),
    30612: (IGPClientSearchUsernameResponse.self            as ResponseMessage.Type,
            IGClientSearchUsernameRequest.Handler.self      as IGRequest.Handler.Type),
    30613: (IGPClientCountRoomHistoryResponse.self          as ResponseMessage.Type,
            IGClientCountRoomHistoryRequest.Handler.self    as IGRequest.Handler.Type),
    30614: (IGPClientMuteRoomResponse.self                  as ResponseMessage.Type,
            IGClientMuteRoomRequest.Handler.self            as IGRequest.Handler.Type),
    30615: (IGPClientPinRoomResponse.self                   as ResponseMessage.Type,
            IGClientPinRoomRequest.Handler.self             as IGRequest.Handler.Type),
    30616: (IGPClientRoomReportResponse.self                as ResponseMessage.Type,
            IGClientRoomReportRequest.Handler.self          as IGRequest.Handler.Type),
    30617: (IGPClientRegisterDeviceResponse.self            as ResponseMessage.Type,
            IGClientRegisterDeviceRequest.Handler.self      as IGRequest.Handler.Type),
    30618: (IGPClientGetPromoteResponse.self                as ResponseMessage.Type,
            IGClientGetPromoteRequest.Handler.self          as IGRequest.Handler.Type),
    30619: (IGPClientGetFavoriteMenuResponse.self           as ResponseMessage.Type,
            IGClientGetFavoriteMenuRequest.Handler.self     as IGRequest.Handler.Type),
    30620: (IGPClientGetDiscoveryResponse.self              as ResponseMessage.Type,
            IGClientGetDiscoveryRequest.Handler.self        as IGRequest.Handler.Type),
    30621: (IGPClientSetDiscoveryItemClickResponse.self     as ResponseMessage.Type,
            IGClientSetDiscoveryItemClickRequest.Handler.self as IGRequest.Handler.Type),
    30623: (IGPClientSetDiscoveryItemAgreementResponse.self     as ResponseMessage.Type,
            IGClientSetDiscoveryItemAgreemnetRequest.Handler.self as IGRequest.Handler.Type),
    30624: (IGPClientGetPollResponse.self                     as ResponseMessage.Type,
            IGPClientGetPollRequest.Handler.self              as IGRequest.Handler.Type),
    30625: (IGPClientSetPollItemClickResponse.self            as ResponseMessage.Type,
            IGPClientSetPollItemClickRequest.Handler.self     as IGRequest.Handler.Type),
    
    
    //File: 307xx
    30700: (IGPFileUploadOptionResponse.self                as ResponseMessage.Type,
            IGFileUploadOptionRequest.Handler.self          as IGRequest.Handler.Type),
    30701: (IGPFileUploadInitResponse.self                  as ResponseMessage.Type,
            IGFileUploadInitRequest.Handler.self            as IGRequest.Handler.Type),
    30702: (IGPFileUploadResponse.self                      as ResponseMessage.Type,
            IGFileUploadRequest.Handler.self                as IGRequest.Handler.Type),
    30703: (IGPFileUploadStatusResponse.self                as ResponseMessage.Type,
            IGFileUploadStatusRequest.Handler.self          as IGRequest.Handler.Type),
    30704: (IGPFileInfoResponse.self                        as ResponseMessage.Type,
            IGFileInfoRequest.Handler.self                  as IGRequest.Handler.Type),
    30705: (IGPFileDownloadResponse.self                    as ResponseMessage.Type,
            IGFileDownloadRequest.Handler.self              as IGRequest.Handler.Type),
    
    //QR: 308xx
    30802: (IGPQrCodeNewDeviceResponse.self                 as ResponseMessage.Type,
            IGQrCodeNewDeviceRequest.Handler.self           as IGRequest.Handler.Type),
    
    
    //Signaling 309xx
    30900: (IGPSignalingGetConfigurationResponse.self      as ResponseMessage.Type,
            IGSignalingGetConfigurationRequest.Handler.self as IGRequest.Handler.Type),
    30901: (IGPSignalingOfferResponse.self                 as ResponseMessage.Type,
            IGSignalingOfferRequest.Handler.self           as IGRequest.Handler.Type),
    30902: (IGPSignalingRingingResponse.self               as ResponseMessage.Type,
            IGSignalingRingingRequest.Handler.self         as IGRequest.Handler.Type),
    30903: (IGPSignalingAcceptResponse.self                as ResponseMessage.Type,
            IGSignalingAcceptRequest.Handler.self          as IGRequest.Handler.Type),
    30904: (IGPSignalingCandidateResponse.self             as ResponseMessage.Type,
            IGSignalingCandidateRequest.Handler.self       as IGRequest.Handler.Type),
    30905: (IGPSignalingLeaveResponse.self                 as ResponseMessage.Type,
            IGSignalingLeaveRequest.Handler.self           as IGRequest.Handler.Type),
    30906: (IGPSignalingSessionHoldResponse.self           as ResponseMessage.Type,
            IGSignalingSessionHoldRequest.Handler.self     as IGRequest.Handler.Type),
    30907: (IGPSignalingGetLogResponse.self                as ResponseMessage.Type,
            IGSignalingGetLogRequest.Handler.self          as IGRequest.Handler.Type),
    30908: (IGPSignalingClearLogResponse.self              as ResponseMessage.Type,
            IGSignalingClearLogRequest.Handler.self        as IGRequest.Handler.Type),
    30909: (IGPSignalingRateResponse.self                  as ResponseMessage.Type,
            IGSignalingRateRequest.Handler.self            as IGRequest.Handler.Type),
    
    31000: (IGPGeoGetRegisterStatusResponse.self           as ResponseMessage.Type,
            IGGeoGetRegisterStatus.Handler.self            as IGRequest.Handler.Type),
    31001: (IGPGeoRegisterResponse.self                    as ResponseMessage.Type,
            IGGeoRegister.Handler.self                     as IGRequest.Handler.Type),
    31002: (IGPGeoUpdatePositionResponse.self              as ResponseMessage.Type,
            IGGeoUpdatePosition.Handler.self               as IGRequest.Handler.Type),
    31003: (IGPGeoGetCommentResponse.self                  as ResponseMessage.Type,
            IGGeoGetComment.Handler.self                   as IGRequest.Handler.Type),
    31004: (IGPGeoUpdateCommentResponse.self               as ResponseMessage.Type,
            IGGeoGetComment.Handler.self                   as IGRequest.Handler.Type),
    31005: (IGPGeoGetNearbyDistanceResponse.self           as ResponseMessage.Type,
            IGGeoGetNearbyDistance.Handler.self            as IGRequest.Handler.Type),
    31006: (IGPGeoGetNearbyCoordinateResponse.self         as ResponseMessage.Type,
            IGGeoGetCoordinateDistance.Handler.self        as IGRequest.Handler.Type),
    31007: (IGPGeoGetConfigurationResponse.self            as ResponseMessage.Type,
            IGGeoGetConfiguration.Handler.self             as IGRequest.Handler.Type),
    
    //Wallet 90xx
    39000: (IGPWalletGetAccessTokenResponse.self           as ResponseMessage.Type,
            IGRequestWalletGetAccessToken.Handler.self     as IGRequest.Handler.Type),
    39001: (IGPWalletPaymentInitResponse.self              as ResponseMessage.Type,
            IGRequestWalletPaymentInit.Handler.self        as IGRequest.Handler.Type),
    39002: (IGPWalletRegisterResponse.self                 as ResponseMessage.Type,
            IGRequestWalletRegister.Handler.self           as IGRequest.Handler.Type),
    
    //Mpl 91xx
    39100: (IGPMplGetBillTokenResponse.self                as ResponseMessage.Type,
            IGMplGetBillToken.Handler.self                 as IGRequest.Handler.Type),
    39101: (IGPMplGetTopupTokenResponse.self               as ResponseMessage.Type,
            IGMplGetTopupToken.Handler.self                as IGRequest.Handler.Type),
    
    39102: (IGPMplGetSalesTokenResponse.self               as ResponseMessage.Type,
            IGMplGetSalesToken.Handler.self                as IGRequest.Handler.Type),
    
    39103: (IGPMplSetSalesResultResponse.self               as ResponseMessage.Type,
            IGMplSetSalesResult.Handler.self                as IGRequest.Handler.Type),
    
    39106: (IGPMplGetCardToCardTokenResponse.self          as ResponseMessage.Type,
            IGMplGetCardToCardToken.Handler.self           as IGRequest.Handler.Type),
    39108: (IGPMplSetCardToCardResultResponse.self         as ResponseMessage.Type,
            IGMplSetCardToCardResult.Handler.self          as IGRequest.Handler.Type),
    39109: (IGPMplTransactionListResponse.self              as ResponseMessage.Type,
            IGMplTransactionList.Handler.self              as IGRequest.Handler.Type),
    39110: (IGPMplTransactionInfoResponse.self         as ResponseMessage.Type,
            IGMplTransactionInfo.Handler.self          as IGRequest.Handler.Type),
    
    //BillInquiry 92xx
    39200: (IGPBillInquiryMciResponse.self                 as ResponseMessage.Type,
            IGBillInquiryMci.Handler.self                  as IGRequest.Handler.Type),
    39201: (IGPBillInquiryTelecomResponse.self             as ResponseMessage.Type,
            IGBillInquiryTelecom.Handler.self              as IGRequest.Handler.Type),
    
    //Push: 600xx
    60000: (IGPPushLoginTokenResponse.self                 as ResponseMessage.Type,
            IGPushLoginTokenRequest.Handler.self           as IGRequest.Handler.Type),
    60001: (IGPPushTwoStepVerificationResponse.self        as ResponseMessage.Type,
            IGPushTwoStepVerificationRequest.Handler.self  as IGRequest.Handler.Type),
    60002: (IGPPushUserInfoExpiredResponse.self            as ResponseMessage.Type,
            IGPushUserInfoExpiredRequest.Handler.self      as IGRequest.Handler.Type),
    60003: (IGPPushRateSignalingResponse.self              as ResponseMessage.Type,
            IGPushRateSignalingRequest.Handler.self        as IGRequest.Handler.Type)
]

var unsecureResponseActionID : [Int] = [30001,30002,30003]

//login is not required for these methods
var actionIdOfMethodsThatCanBeSentWithoutBeingLoggedIn : [Int] = [2, 100, 101, 102,131,132, 138, 139, 140, 500, 501, 502, 503, 802]
var waitingListActionId : [Int] = []//currently not exist any waiting actionId


class IGRequestManager {
    //MARK: Initilizers
    static let sharedManager = IGRequestManager()
    
    let disposeBag = DisposeBag()
    private let TIME_OUT: Int64  = 10 //sencond
    private let TIME_OUT_LOGIN: Int64  = 15 //sencond
    private var queuedRequests   = [String : IGRequestWrapper]()
    private var pendingRequests  = [String : IGRequestWrapper]()
    private var resolvedRequests = [String : IGRequestWrapper]()
    
    /* use "async(flags: .barrier)" for "writes on data"  AND  use "sync" for "read and assign value" */
    fileprivate var syncroniseQueue = DispatchQueue(label: "thread-safe-obj", attributes: .concurrent)
    
    private init() {
        
        IGAppManager.sharedManager.isUserLoggedIn.asObservable().subscribe(onNext: { (loginState) in
            if loginState {
                self.syncroniseQueue.async(flags: .barrier) {
                    if self.queuedRequests.count > 0 {
                        self.queuedRequests.forEach {
                            let id = $0.key
                            let requestWrapper = $0.value
                            self.queuedRequests.removeValue(forKey: id)
                            self.addRequestIDAndSend(requestWrappers: requestWrapper)
                        }
                    }
                }
            }
        }, onError: { (error) in
            
        }, onCompleted: {
            
        }, onDisposed: {
            
        }).disposed(by: disposeBag)
    }
    
    //MARK: Public Methods
    //MARK: Send
    func addRequestIDAndSend(requestWrappers : IGRequestWrapper ...) {
        if requestWrappers.count > 0 {
            
            for requestWrapper in requestWrappers {
                var shouldSendRequest = false
                
                if IGAppManager.sharedManager.isUserLoggedIn.value {
                    shouldSendRequest = true
                } else if actionIdOfMethodsThatCanBeSentWithoutBeingLoggedIn.contains(requestWrapper.actionId) {
                    shouldSendRequest = true
                }
                
                self.syncroniseQueue.async(flags: .barrier) {
                    if let request = self.generateIGRequestObject() {
                        self.pendingRequests[request.igpID] = requestWrapper
                        requestWrapper.id = request.igpID
                        requestWrapper.message.igpRequest = request
                        requestWrapper.time = IGGlobal.getCurrentMillis()
                    }
                    
                    if shouldSendRequest {
                        IGWebSocketManager.sharedManager.send(requestW: requestWrapper)
                    } else {
                        if waitingListActionId.contains(requestWrapper.actionId) {
                            self.syncroniseQueue.async(flags: .barrier) {
                                self.queuedRequests[self.generateRandomRequestID()] = requestWrapper
                            }
                        }
                    }

                    /**
                     just start call 'checkTimeOut' when count of 'pendingRequests' is one, because when
                     count of this object is more than one 'checkTimeOut' is calling at loop
                     */
                    print("PPP || self.pendingRequests.count: \(self.pendingRequests.count)")
                    if self.pendingRequests.count == 1 {
                        print("PPP || count is 1")
                        self.checkTimeOut()
                    }
                }
            }
        }
    }
    
    func userDidLogout() {
        queuedRequests   = [String : IGRequestWrapper]()
        pendingRequests  = [String : IGRequestWrapper]()
        resolvedRequests = [String : IGRequestWrapper]()
    }

    //MARK: Receive
    func didReceive(decryptedData: NSData) {
        //var convertedData = NSData(data: decryptedData)
        let firstTwoByte = decryptedData.subdata(with: NSMakeRange(0, 2))
        let payload = decryptedData.subdata(with: NSMakeRange(2, decryptedData.length-2))
        var actionIDArray = [UInt8](repeating:0, count:firstTwoByte.count)
        firstTwoByte.copyBytes(to: &actionIDArray, count: firstTwoByte.count)
        actionIDArray.reverse() // this line is because the actionID is little-endian
        
        var actionID = 0
        for byte in actionIDArray {
            actionID = actionID << 8
            actionID = actionID | Int(byte)
        }
        
        if !IGWebSocketManager.sharedManager.isSecureConnection() && !unsecureResponseActionID.contains(actionID) {
            return
        }
        
        
        if let lookupTableResult = protoClassesLookupTable[actionID] {
            let protoClassName = lookupTableResult.proto
            do {
                let responseProtoMessage = try protoClassName.init(serializedData: payload)
                let requestHandlerClassName = lookupTableResult.reponseHandler
                
//                print("\n______________________________\nRESPONSE ➤➤➤ Action ID: \(actionID)   || \(responseProtoMessage) \n------------------------------\n")
                
                let response = responseProtoMessage.igpResponse
                var correspondingRequestWrapper: IGRequestWrapper!
                var resolvedRequest: IGRequestWrapper!
                self.syncroniseQueue.sync {
                    if let pendingRequest = pendingRequests[response.igpID] {
                        correspondingRequestWrapper = pendingRequest
                    } else {
                        resolvedRequest = resolvedRequests[response.igpID]
                    }
                }
                
                if correspondingRequestWrapper != nil {
                    if actionID == 0 { //-> failed
                        let errorProtoMessage = responseProtoMessage as! IGPErrorResponse
                        let errorData = IGErrorRequest.Handler.interpret(response: errorProtoMessage)
                        if let error = correspondingRequestWrapper.error {
                            error(errorData.error, errorData.wait)
                        } else if let errorPowerful = correspondingRequestWrapper.errorPowerful {
                            errorPowerful(errorData.error, errorData.wait, correspondingRequestWrapper)
                        }
                    } else { // -> successful
                        
                        /* return callback to each one of the callbacks that has value.
                         */
                        if let success = correspondingRequestWrapper.success {
                            success(responseProtoMessage)
                        } else if let successPowerful = correspondingRequestWrapper.successPowerful {
                            successPowerful(responseProtoMessage, correspondingRequestWrapper)
                        } else {
                            requestHandlerClassName.handlePush(responseProtoMessage: responseProtoMessage)
                        }
                    }
                    self.syncroniseQueue.async(flags: .barrier) {
                        self.resolvedRequests[response.igpID] = correspondingRequestWrapper
                        self.pendingRequests[response.igpID] = nil
                    }
                } else if resolvedRequest != nil {
                    print ("✦ \(NSDate.timeIntervalSinceReferenceDate) -----XXX Response is already resolved")
                } else {
                    //this is a `pushed` message
                    //call its corresponding handler class to handle push
                    requestHandlerClassName.handlePush(responseProtoMessage: responseProtoMessage)
                }
            } catch let error {
                print ("✦ \(NSDate.timeIntervalSinceReferenceDate) ----- Error Parsing Proto From Binary Data")
                print (error)
            }
            
        } else {
            //at this point ignore this data
            //maybe new command (protos) added to server but
            //not supported yet by this version of iOS client
            //print("\n\n RESPONSE ➤➤➤ Action ID: \(actionID)   || This id not exist in LookUpTable \n\n")
        }
    }
    
    
    func checkTimeOut() {
        //check if request is still pending
        self.syncroniseQueue.async(flags: .barrier) {
            for requestWrapper in self.pendingRequests.values {
                
                var timeOut = self.TIME_OUT
                if requestWrapper.actionId == 102 {
                    timeOut = self.TIME_OUT_LOGIN
                }
                
                if let indexOfRequest = self.pendingRequests.index(forKey: requestWrapper.id), self.isTimedOut(requestTime: requestWrapper.time, config: timeOut){
                    self.resolvedRequests[requestWrapper.id] = requestWrapper
                    self.pendingRequests.remove(at: indexOfRequest)
                    if let error = requestWrapper.error {
                        print("\n______________________________\nTIME OUT ➤➤➤ Action ID: \(requestWrapper.actionId)   || \(String(describing: requestWrapper.message)) \n------------------------------\n")
                        error(.timeout, nil)
                    } else if let errorPowerful = requestWrapper.errorPowerful {
                        errorPowerful(.timeout, nil, requestWrapper)
                        print("\n______________________________\nTIME OUT ➤➤➤ Action ID: \(requestWrapper.actionId)   || \(String(describing: requestWrapper.message)) \n------------------------------\n")
                    }
                }
            }
            
            if self.pendingRequests.count == 0 {
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.checkTimeOut()
            }
        }
    }
    
    private func isTimedOut(requestTime: Int64, config: Int64) -> Bool {
        let timeDifference = IGGlobal.getCurrentMillis() - requestTime
        if timeDifference >= (config * 1000) {
            return true
        }
        return false
    }
    
    func cancelRequest(identity: String) {
        self.syncroniseQueue.async(flags: .barrier) {
            for requestWrapper in self.pendingRequests.values {
                if let identityValue = requestWrapper.identity as? String, identityValue == identity {
                    self.resolvedRequests[requestWrapper.id] = requestWrapper
                    self.pendingRequests[requestWrapper.id] = nil
                }
            }
        }
    }
    
    //MARK: Private Methods
    func generateIGRequestObject() -> IGPRequest? {
        var requestMessage = IGPRequest()
        requestMessage.igpID = generateRandomRequestID()
        return requestMessage
        
    }
    
    private func generateRandomRequestID() -> String {
        return IGGlobal.randomString(length: 48)
    }
    
    private func generateRandomBatchID() -> String {
        return IGGlobal.randomString(length: 48)
    }
    
}

