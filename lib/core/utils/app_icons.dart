import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// App Icons Utility
/// Maps common icon names to SVG file paths
/// Provides helper methods for loading SVG icons
class AppIcons {
  // Base paths for SVG icons
  static const String _basePath = 'assets/images/icons'; // Legacy path
  static const String _iconsBasePath = 'assets/icons'; // New icons directory
  
  // Icon style subdirectories
  static const String _outline = 'outline';
  static const String _bold = 'bold';
  static const String _bulk = 'bulk';
  static const String _linear = 'linear';
  static const String _broken = 'broken';
  static const String _twotone = 'twotone';
  
  /// Get icon path from new icons directory with specified style
  /// Default style is 'outline' (for buttons and interactive elements)
  static String getIconPath(String iconName, {String style = _outline}) {
    return '$_iconsBasePath/$style/$iconName.svg';
  }
  
  /// Get icon path with outline style (for buttons and interactive elements)
  static String getIconOutline(String iconName) {
    return getIconPath(iconName, style: _outline);
  }
  
  /// Get icon path with bold style (for filled icons)
  static String getIconBold(String iconName) {
    return getIconPath(iconName, style: _bold);
  }
  
  /// Get icon path with bulk style (for filled icons alternative)
  static String getIconBulk(String iconName) {
    return getIconPath(iconName, style: _bulk);
  }

  // Navigation Icons
  static const String home = '$_basePath/home.svg';
  static const String home2 = '$_basePath/home-2.svg';
  static const String discover = '$_basePath/discover.svg';
  static const String discover1 = '$_basePath/discover-1.svg';
  static const String heart = '$_basePath/heart.svg';
  static const String like = '$_basePath/like.svg';
  static const String like1 = '$_basePath/like-1.svg';
  static const String message = '$_basePath/message-2.svg';
  static const String messageCircle = '$_basePath/message-circle.svg';
  static const String messageSquare = '$_basePath/message-square.svg';
  static String get chatBubbleOutline => getIconPath('message'); // For chat_bubble_outline
  static String get commentOutlined => getIconPath('message'); // For comment_outlined (use message icon)
  static String get user => getIconPath('user'); // Use outline style
  static String get profile => getIconPath('profile'); // Use outline style
  static String get userOutline => getIconPath('user'); // For user icon
  static const String settings = '$_basePath/setting-2.svg';
  // Search icons - prefer new path
  static String get search => getIconPath('search-normal');
  static String get searchZoomIn => getIconPath('search-zoom-in');
  static String get searchZoomOut => getIconPath('search-zoom-out');
  static const String searchLegacy = '$_basePath/search-normal.svg';
  static const String searchZoomInLegacy = '$_basePath/search-zoom-in.svg';
  static const String searchZoomOutLegacy = '$_basePath/search-zoom-out.svg';

  // Action Icons
  static const String add = '$_basePath/add.svg';
  static const String addCircle = '$_basePath/add-circle.svg';
  static const String addSquare = '$_basePath/add-square.svg';
  static const String edit = '$_basePath/edit.svg';
  static const String edit2 = '$_basePath/edit-2.svg';
  static const String delete = '$_basePath/trash.svg';
  // Close icons - use new path
  static String get close => getIconPath('close-circle');
  static String get closeSquare => getIconPath('close-square');
  // Check icons - use new path
  static String get check => getIconPath('tick-circle');
  static String get checkSquare => getIconPath('tick-square');
  static String get checkCircle => getIconPath('tick-circle');
  static const String save = '$_basePath/save-2.svg';
  static const String share = '$_basePath/share.svg';
  static String get shareOutlined => getIconPath('share'); // For share_outlined
  static const String share1 = '$_basePath/share-1.svg';
  static const String download = '$_basePath/document-download.svg';
  static const String upload = '$_basePath/document-upload.svg';
  static const String copy = '$_basePath/copy.svg';
  static const String filter = '$_basePath/filter.svg';
  static const String filterSquare = '$_basePath/filter-square.svg';
  static const String sort = '$_basePath/sort.svg';

  // Arrow Icons - prefer new path
  static String get arrowLeft => getIconPath('arrow-left');
  static String get arrowLeft2 => getIconPath('arrow-left-2');
  static String get arrowRight => getIconPath('arrow-right');
  static String get arrowRight2 => getIconPath('arrow-right-2');
  static String get arrowUp => getIconPath('arrow-up');
  static String get arrowUp2 => getIconPath('arrow-up-2');
  static String get arrowDown => getIconPath('arrow-down');
  static String get arrowDown2 => getIconPath('arrow-down-2');
  static String get back => getIconPath('arrow-left');
  static String get forward => getIconPath('arrow-right');
  static String get chevronRight => getIconPath('arrow-right-2'); // For chevron_right
  static String get chevronLeft => getIconPath('arrow-left-2'); // For chevron_left
  // Legacy paths
  static const String arrowLeftLegacy = '$_basePath/arrow-left.svg';
  static const String arrowRightLegacy = '$_basePath/arrow-right.svg';

  // Media Icons
  static String get camera => getIconPath('camera'); // Use outline style
  static const String cameraSlash = '$_basePath/camera-slash.svg';
  static String get gallery => getIconPath('gallery'); // Use outline style
  static String get galleryAdd => getIconPath('gallery-add'); // Use outline style
  static const String galleryEdit = '$_basePath/gallery-edit.svg';
  static const String image = '$_basePath/image.svg';
  static const String video = '$_basePath/video.svg';
  static const String videoSquare = '$_basePath/video-square.svg';
  static const String microphone = '$_basePath/microphone.svg';
  static const String microphone2 = '$_basePath/microphone-2.svg';
  static const String microphoneSlash = '$_basePath/microphone-slash.svg';
  static const String play = '$_basePath/play.svg';
  static const String playCircle = '$_basePath/play-circle.svg';
  static const String pause = '$_basePath/pause.svg';
  static const String pauseCircle = '$_basePath/pause-circle.svg';
  static const String stop = '$_basePath/stop.svg';
  static const String stopCircle = '$_basePath/stop-circle.svg';

  // Communication Icons
  static const String call = '$_basePath/call.svg';
  static String get phone => getIconPath('call'); // Alias for phone icon
  static const String callIncoming = '$_basePath/call-incoming.svg';
  static const String callOutgoing = '$_basePath/call-outgoing.svg';
  static const String callMissed = '$_basePath/call-slash.svg';
  static const String videoCall = '$_basePath/video.svg';
  static const String send = '$_basePath/send.svg';
  static String get sendIcon => getIconPath('send'); // For send icon
  static const String send2 = '$_basePath/send-2.svg';
  static String get email => getIconPath('message'); // For email icon (use message icon)
  static String get emailOutlined => getIconPath('message'); // For email_outlined
  static const String attach = '$_basePath/attach-circle.svg';
  static const String attachSquare = '$_basePath/attach-square.svg';
  static const String emoji = '$_basePath/emoji-happy.svg';
  static const String emojiSad = '$_basePath/emoji-sad.svg';
  static const String emojiNormal = '$_basePath/emoji-normal.svg';

  // Social & Interaction Icons
  static const String likeTag = '$_basePath/like-tag.svg';
  static const String likeShapes = '$_basePath/like-shapes.svg';
  static const String dislike = '$_basePath/dislike.svg';
  static const String likeDislike = '$_basePath/like-dislike.svg';
  static const String heartAdd = '$_basePath/heart-add.svg';
  static const String heartRemove = '$_basePath/heart-remove.svg';
  static const String heartTick = '$_basePath/heart-tick.svg';
  static const String heartSlash = '$_basePath/heart-slash.svg';
  static String get favorite => getIconPath('heart'); // For favorite icon
  static String get favoriteBorder => getIconPath('heart'); // For favorite_border (use same icon)
  static String get heartOutline => getIconPath('heart'); // For heart icon in outline style
  static const String star = '$_basePath/star.svg';
  static const String star1 = '$_basePath/star-1.svg';
  static const String magicStar = '$_basePath/magic-star.svg';
  static const String bookmark = '$_basePath/bookmark.svg';
  static const String bookmark2 = '$_basePath/bookmark-2.svg';

  // Notification & Status Icons
  static const String notification = '$_basePath/notification.svg';
  static const String notification1 = '$_basePath/notification-1.svg';
  static const String notificationBing = '$_basePath/notification-bing.svg';
  static const String notificationFavorite = '$_basePath/notification-favorite.svg';
  static const String bell = '$_basePath/notification.svg';
  static const String bellSlash = '$_basePath/notification-slash.svg';
  static const String online = '$_basePath/status.svg';
  static const String offline = '$_basePath/status-offline.svg';

  // Security & Privacy Icons
  static String get lock => getIconPath('lock'); // Use new icons directory
  static const String lock1 = '$_basePath/lock-1.svg';
  static const String lockCircle = '$_basePath/lock-circle.svg';
  static const String lockSlash = '$_basePath/lock-slash.svg';
  static String get lockOutline => getIconPath('lock'); // For lock_outline
  static String get lockOutlined => getIconPath('lock'); // For lock_outlined
  static String get lockReset => getIconPath('lock'); // For lock reset (use lock icon)
  static const String unlock = '$_basePath/unlock.svg';
  static String get eye => getIconPath('eye'); // Use new icons directory
  static const String eyeSlash = '$_basePath/eye-slash.svg';
  static String get visibility => getIconPath('eye'); // For visibility
  static String get visibilityOff => getIconPath('eye-slash'); // For visibility_off
  static const String shield = '$_basePath/shield.svg';
  static const String shieldTick = '$_basePath/shield-tick.svg';
  static const String shieldSlash = '$_basePath/shield-slash.svg';
  static const String key = '$_basePath/key.svg';
  static const String keySquare = '$_basePath/key-square.svg';
  static const String fingerPrint = '$_basePath/finger-scan.svg';
  static const String fingerCircle = '$_basePath/finger-cricle.svg';

  // Profile & Account Icons
  static const String userSquare = '$_basePath/user-square.svg';
  static const String userAdd = '$_basePath/user-add.svg';
  static const String userRemove = '$_basePath/user-remove.svg';
  static const String userEdit = '$_basePath/user-edit.svg';
  static const String userTick = '$_basePath/user-tick.svg';
  static const String userTag = '$_basePath/user-tag.svg';
  static const String profileCircle = '$_basePath/profile-circle.svg';
  static const String profileDelete = '$_basePath/profile-delete.svg';
  static const String login = '$_basePath/login.svg';
  static const String login1 = '$_basePath/login-1.svg';
  static const String logout = '$_basePath/logout.svg';
  static const String logout1 = '$_basePath/logout-1.svg';

  // Verification & Badge Icons
  static const String verify = '$_basePath/verify.svg';
  static const String tickCircle = '$_basePath/tick-circle.svg';
  static const String tickSquare = '$_basePath/tick-square.svg';
  static const String award = '$_basePath/award.svg';
  static const String medal = '$_basePath/medal.svg';
  static const String medalStar = '$_basePath/medal-star.svg';
  static const String crown = '$_basePath/crown.svg';
  static const String crown1 = '$_basePath/crown-1.svg';
  static const String badge = '$_basePath/badge.svg';

  // Settings & Preferences Icons
  static const String setting = '$_basePath/setting.svg';
  static const String setting2 = '$_basePath/setting-2.svg';
  static const String setting3 = '$_basePath/setting-3.svg';
  static const String setting4 = '$_basePath/setting-4.svg';
  static const String setting5 = '$_basePath/setting-5.svg';
  static const String menu = '$_basePath/menu.svg';
  static const String menu1 = '$_basePath/menu-1.svg';
  static const String more = '$_basePath/more.svg';
  static const String more2 = '$_basePath/more-2.svg';
  static const String moreCircle = '$_basePath/more-circle.svg';
  static const String moreSquare = '$_basePath/more-square.svg';

  // Payment & Subscription Icons
  static const String card = '$_basePath/card.svg';
  static const String cardAdd = '$_basePath/card-add.svg';
  static const String cardRemove = '$_basePath/card-remove.svg';
  static const String cardTick = '$_basePath/card-tick.svg';
  static const String wallet = '$_basePath/wallet.svg';
  static const String wallet1 = '$_basePath/wallet-1.svg';
  static const String wallet2 = '$_basePath/wallet-2.svg';
  static const String wallet3 = '$_basePath/wallet-3.svg';
  static const String coin = '$_basePath/coin.svg';
  static const String coin1 = '$_basePath/coin-1.svg';
  static const String dollarCircle = '$_basePath/dollar-circle.svg';
  static const String dollarSquare = '$_basePath/dollar-square.svg';
  static const String receipt = '$_basePath/receipt.svg';
  static const String receipt1 = '$_basePath/receipt-1.svg';
  static const String receipt2 = '$_basePath/receipt-2.svg';
  static const String receipt21 = '$_basePath/receipt-2-1.svg';
  static const String receiptDiscount = '$_basePath/receipt-discount.svg';
  static const String receiptEdit = '$_basePath/receipt-edit.svg';
  static const String receiptItem = '$_basePath/receipt-item.svg';
  static const String receiptSearch = '$_basePath/receipt-search.svg';
  static const String receiptSquare = '$_basePath/receipt-square.svg';
  static const String receiptText = '$_basePath/receipt-text.svg';

  // Location Icons
  static const String location = '$_basePath/location.svg';
  static const String locationAdd = '$_basePath/location-add.svg';
  static const String locationCross = '$_basePath/location-cross.svg';
  static const String locationMinus = '$_basePath/location-minus.svg';
  static const String locationTick = '$_basePath/location-tick.svg';
  static const String locationSlash = '$_basePath/location-slash.svg';
  static const String gps = '$_basePath/gps.svg';
  static const String gpsSlash = '$_basePath/gps-slash.svg';
  static const String map = '$_basePath/map.svg';
  static const String map1 = '$_basePath/map-1.svg';

  // Time & Calendar Icons
  static String get calendarToday => getIconPath('calendar'); // For calendar_today
  static String get calendar => getIconPath('calendar'); // Use outline style
  static const String clock = '$_basePath/clock.svg';
  static const String clock1 = '$_basePath/clock-1.svg';
  static const String calendar1 = '$_basePath/calendar-1.svg';
  static const String calendar2 = '$_basePath/calendar-2.svg';
  static const String calendarAdd = '$_basePath/calendar-add.svg';
  static const String calendarEdit = '$_basePath/calendar-edit.svg';
  static const String calendarRemove = '$_basePath/calendar-remove.svg';
  static const String calendarTick = '$_basePath/calendar-tick.svg';
  static const String timer = '$_basePath/timer.svg';
  static const String timer1 = '$_basePath/timer-1.svg';
  static const String timerPause = '$_basePath/timer-pause.svg';
  static const String timerStart = '$_basePath/timer-start.svg';

  // Info & Help Icons
  static const String infoCircle = '$_basePath/info-circle.svg';
  static String get info => getIconPath('info-circle'); // For info icon
  static const String information = '$_basePath/information.svg';
  static const String question = '$_basePath/question-mark.svg';
  static const String questionCircle = '$_basePath/question-mark-circle.svg';
  static const String danger = '$_basePath/danger.svg';
  static const String warning = '$_basePath/warning-2.svg';
  static const String warning2 = '$_basePath/warning-2.svg';
  static const String help = '$_basePath/message-question.svg';
  static const String support = '$_basePath/24-support.svg';
  static const String lifebuoy = '$_basePath/lifebuoy.svg';

  // File & Document Icons
  static const String document = '$_basePath/document.svg';
  static const String document1 = '$_basePath/document-1.svg';
  static const String documentText = '$_basePath/document-text.svg';
  static const String documentText1 = '$_basePath/document-text-1.svg';
  static const String documentDownload = '$_basePath/document-download.svg';
  static const String documentUpload = '$_basePath/document-upload.svg';
  static const String folder = '$_basePath/folder.svg';
  static const String folder2 = '$_basePath/folder-2.svg';
  static const String folderAdd = '$_basePath/folder-add.svg';
  static const String folderOpen = '$_basePath/folder-open.svg';
  static const String archive = '$_basePath/archive.svg';
  static const String archive1 = '$_basePath/archive-1.svg';
  static const String archive2 = '$_basePath/archive-2.svg';

  // Network & Connection Icons
  static const String wifi = '$_basePath/wifi.svg';
  static const String wifiSquare = '$_basePath/wifi-square.svg';
  static const String bluetooth = '$_basePath/bluetooth.svg';
  static const String bluetooth2 = '$_basePath/bluetooth-2.svg';
  static const String cloud = '$_basePath/cloud.svg';
  static const String cloudAdd = '$_basePath/cloud-add.svg';
  static const String cloudRemove = '$_basePath/cloud-remove.svg';
  static const String cloudConnection = '$_basePath/cloud-connection.svg';
  static const String refresh = '$_basePath/refresh.svg';
  static const String refresh2 = '$_basePath/refresh-2.svg';
  static const String refreshCircle = '$_basePath/refresh-circle.svg';
  static const String refreshLeft = '$_basePath/refresh-left.svg';
  static const String refreshRight = '$_basePath/refresh-right.svg';
  static const String refreshSquare = '$_basePath/refresh-square.svg';
  static const String refreshSquare2 = '$_basePath/refresh-square-2.svg';

  // Error & Status Icons
  static const String error = '$_basePath/danger.svg';
  static const String success = '$_basePath/tick-circle.svg';
  static const String warningTriangle = '$_basePath/warning-2.svg';
  static String get errorOutline => getIconPath('info-circle'); // For error_outline

  // Premium & Special Icons
  static const String flash = '$_basePath/flash.svg';
  static const String flash1 = '$_basePath/flash-1.svg';
  static const String flashCircle = '$_basePath/flash-circle.svg';
  static const String flashCircle1 = '$_basePath/flash-circle-1.svg';
  static const String gift = '$_basePath/gift.svg';
  static const String discount = '$_basePath/discount-circle.svg';
  static const String discountShape = '$_basePath/discount-shape.svg';

  // Privacy & Safety Icons
  static const String block = '$_basePath/forbidden.svg';
  static const String block2 = '$_basePath/forbidden-2.svg';
  static const String report = '$_basePath/info-circle.svg';
  static const String flag = '$_basePath/flag.svg';
  static const String flag2 = '$_basePath/flag-2.svg';

  // Empty state & placeholder icons
  static const String emptyBox = '$_basePath/box.svg';
  static const String emptyFolder = '$_basePath/folder.svg';
  static const String emptyDocument = '$_basePath/document.svg';
  
  /// Get icon path by name (fallback method) - uses new icons directory
  static String? getIconPathByName(String iconName, {String style = _outline}) {
    // Remove common prefixes/suffixes and normalize
    final normalized = iconName.toLowerCase().replaceAll(RegExp(r'[_\s-]'), '');
    
    // Try to find matching icon in new icons directory
    return getIconPath(iconName, style: style);
  }
}

/// SVG Icon Widget
/// A reusable widget for displaying SVG icons with theme support
class AppSvgIcon extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final double? size;
  final Color? color;
  final BoxFit fit;
  final Alignment alignment;

  const AppSvgIcon({
    Key? key,
    required this.assetPath,
    this.width,
    this.height,
    this.size,
    this.color,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Use size if provided, otherwise use width/height
    final iconWidth = size ?? width ?? 24.0;
    final iconHeight = size ?? height ?? 24.0;
    
    // Default color based on theme if not provided
    final iconColor = color ?? (isDark 
        ? const Color(0xFFFFFFFF) 
        : const Color(0xFF000000));

    try {
      return SvgPicture.asset(
        assetPath,
        width: iconWidth,
        height: iconHeight,
        fit: fit,
        alignment: alignment,
        colorFilter: color != null 
            ? ColorFilter.mode(iconColor, BlendMode.srcIn)
            : null,
        placeholderBuilder: (context) => SizedBox(
          width: iconWidth,
          height: iconHeight,
          child: Icon(
            Icons.image_not_supported,
            size: iconWidth * 0.8,
            color: iconColor.withOpacity(0.5),
          ),
        ),
        // Add error handling with fallback
        semanticsLabel: assetPath.split('/').last,
      );
    } catch (e) {
      // Fallback to Material icon if SVG fails to load
      debugPrint('Failed to load SVG icon: $assetPath - $e');
      return Icon(
        Icons.error_outline,
        size: iconWidth,
        color: iconColor,
      );
    }
  }
}

/// Icon Button with SVG support
class AppSvgIconButton extends StatelessWidget {
  final String assetPath;
  final VoidCallback? onPressed;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool isActive;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;

  const AppSvgIconButton({
    Key? key,
    required this.assetPath,
    this.onPressed,
    this.size = 48.0,
    this.backgroundColor,
    this.iconColor,
    this.isActive = false,
    this.padding,
    this.semanticLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bgColor = backgroundColor ??
        (isActive
            ? const Color(0xFF8A2BE2) // accentPurple
            : (isDark 
                ? const Color(0xFF121214) // surfaceDark
                : const Color(0xFFF5F5F7))); // surfaceLight
    
    final iconColorValue = iconColor ??
        (isActive
            ? Colors.white
            : (isDark 
                ? const Color(0xFFFFFFFF) // textPrimaryDark
                : const Color(0xFF000000))); // textPrimaryLight

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppSvgIcon(
            assetPath: assetPath,
            size: size * 0.5,
            color: iconColorValue,
          ),
        ),
      ),
    );
  }
}

