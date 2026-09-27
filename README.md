<div align="center">
  <img src="logo/ic_launcher.png" width="96" alt="eunix logo" />

  # eunix

  **A network toolkit for Android, built with Flutter**
  **جعبه‌ابزار شبکه برای اندروید، ساخته‌شده با Flutter**

  <p>
    <a href="#english">English</a> •
    <a href="#فارسی">فارسی</a>
  </p>
</div>

---

<a name="english"></a>
## English

### Overview

**eunix** is an Android app that bundles a set of common network utilities — similar in spirit to classic Unix/Linux command-line tools (`nc`, `ping`, `traceroute`, `nmap`) — into a single mobile interface. It's meant for network troubleshooting, local device discovery, and quick TCP/UDP/HTTP experimentation directly from a phone.

The UI uses a dark, monospace, terminal-inspired theme.

### Features

Tools are grouped into four categories:

**Netcat Tools**
- TCP Client — open an outgoing TCP connection
- TCP Server — listen for incoming TCP connections
- UDP Client — send and receive UDP packets

**Discovery Tools**
- TCP Proxy — forward traffic between endpoints
- Port Scanner — scan for open ports
- Ping Tool — ICMP ping test
- Traceroute — trace the hop-by-hop path to a host
- ARP Scanner — discover local network devices via ARP
- IP Finder — scan the local network for active hosts

**Lookup Tools**
- DNS Lookup — resolve a domain's DNS records
- Whois Lookup — view domain registration info

**System Tools**
- Network Dashboard — device and network info
- WiFi Scanner — scan nearby WiFi networks
- HTTP Client — send custom HTTP requests

The home screen also shows the device's current IP address and connected SSID.

### Tech Stack

Only dependencies actually used in the codebase:

| Purpose | Package |
|---|---|
| Framework | [Flutter](https://flutter.dev) (Dart SDK ^3.9.2) |
| UI components | [shadcn_flutter](https://pub.dev/packages/shadcn_flutter) |
| Network info (IP/SSID) | [network_info_plus](https://pub.dev/packages/network_info_plus) |
| WiFi scanning | [wifi_scan](https://pub.dev/packages/wifi_scan) |
| Runtime permissions | [permission_handler](https://pub.dev/packages/permission_handler) |
| HTTP requests | [http](https://pub.dev/packages/http) |

### Getting Started

**Prerequisites:** Flutter SDK installed ([install guide](https://docs.flutter.dev/get-started/install)).

```bash
git clone https://github.com/EhsanFiruzi/eunix.git
cd eunix
flutter pub get
flutter run
```

Build a release APK:

```bash
flutter build apk --release
```

### Android Permissions

Since eunix operates on the network layer (port/ARP/WiFi scanning), it requests runtime permissions such as network access, location (required by Android for WiFi scans), and WiFi state access.

### Project Structure

```
lib/
 ├─ main.dart                    # App entry point
 └─ pages/
     ├─ home_page.dart           # Home screen and tool categories
     ├─ tcp_client_page.dart
     ├─ tcp_server_page.dart
     ├─ udp_client_page.dart
     ├─ tcp_proxy_page.dart
     ├─ port_scanner_page.dart
     ├─ ping_tool_page.dart
     ├─ traceroute_page.dart
     ├─ arp_scanner_page.dart
     ├─ ip_finder_page.dart
     ├─ dns_lookup_page.dart
     ├─ whois_lookup_page.dart
     ├─ network_dashbord_page.dart
     ├─ wifi_scanner_page.dart
     └─ http_client_page.dart
```

### ⚠️ Disclaimer

The tools in this app (port scanner, ARP scanner, etc.) are intended for use only on networks and devices you own or have explicit permission to test. Using them against networks or devices you don't own may be illegal in your jurisdiction.

### Author

Built by [Ehsan Firuzi](https://github.com/EhsanFiruzi)

### License

This project is licensed under the [MIT License](LICENSE) — you're free to use, modify, and distribute it, including in derivative works.

### Contributing

Contributions are welcome. Feel free to fork the repo, fix bugs, or improve the code, then open a pull request.

---

<a name="فارسی"></a>
## فارسی

### درباره پروژه

**eunix** یک اپلیکیشن اندرویدی است که مجموعه‌ای از ابزارهای رایج شبکه را — با روحیه‌ای شبیه به ابزارهای خط‌فرمان یونیکس/لینوکس مانند `nc`, `ping`, `traceroute`, `nmap` — در یک رابط کاربری موبایل واحد کنار هم قرار می‌دهد. این اپ برای عیب‌یابی شبکه، شناسایی دستگاه‌های محلی و آزمایش سریع پروتکل‌های TCP/UDP/HTTP مستقیماً از روی گوشی طراحی شده است.

رابط کاربری از تم تیره، فونت مونواسپیس و ظاهری الهام‌گرفته از ترمینال استفاده می‌کند.

### امکانات

ابزارها در چهار دسته سازمان‌دهی شده‌اند:

**Netcat Tools**
- TCP Client — برقراری اتصال خروجی TCP
- TCP Server — گوش‌دادن به اتصالات ورودی TCP
- UDP Client — ارسال و دریافت بسته‌های UDP

**Discovery Tools**
- TCP Proxy — فوروارد کردن ترافیک بین دو مقصد
- Port Scanner — اسکن پورت‌های باز
- Ping Tool — تست ICMP ping
- Traceroute — ردیابی مسیر عبور بسته‌ها (hop به hop)
- ARP Scanner — شناسایی دستگاه‌های شبکه محلی از طریق ARP
- IP Finder — اسکن شبکه محلی برای یافتن میزبان‌های فعال

**Lookup Tools**
- DNS Lookup — استخراج رکوردهای DNS یک دامنه
- Whois Lookup — نمایش اطلاعات ثبت دامنه

**System Tools**
- Network Dashboard — نمایش اطلاعات دستگاه و شبکه
- WiFi Scanner — اسکن شبکه‌های WiFi اطراف
- HTTP Client — ارسال درخواست‌های HTTP دلخواه

صفحه اصلی اپ همچنین آی‌پی فعلی دستگاه و SSID شبکه‌ی متصل‌شده را نمایش می‌دهد.

### تکنولوژی‌های استفاده‌شده

فقط پکیج‌هایی که واقعاً در کد استفاده شده‌اند:

| کاربرد | پکیج |
|---|---|
| فریمورک | [Flutter](https://flutter.dev) (Dart SDK ^3.9.2) |
| کامپوننت‌های رابط کاربری | [shadcn_flutter](https://pub.dev/packages/shadcn_flutter) |
| اطلاعات شبکه (IP/SSID) | [network_info_plus](https://pub.dev/packages/network_info_plus) |
| اسکن WiFi | [wifi_scan](https://pub.dev/packages/wifi_scan) |
| مدیریت مجوزهای زمان اجرا | [permission_handler](https://pub.dev/packages/permission_handler) |
| درخواست‌های HTTP | [http](https://pub.dev/packages/http) |

### نصب و اجرا

**پیش‌نیاز:** نصب Flutter SDK ([راهنمای نصب](https://docs.flutter.dev/get-started/install)).

```bash
git clone https://github.com/EhsanFiruzi/eunix.git
cd eunix
flutter pub get
flutter run
```

ساخت نسخه‌ی نصبی (release APK):

```bash
flutter build apk --release
```

### مجوزهای اندروید

از آنجا که eunix روی لایه شبکه کار می‌کند (اسکن پورت، ARP، WiFi)، در زمان اجرا مجوزهایی مانند دسترسی به شبکه، موقعیت مکانی (که اندروید برای اسکن WiFi الزامی می‌کند) و دسترسی به وضعیت WiFi را درخواست می‌کند.

### ساختار پروژه

```
lib/
 ├─ main.dart                    # نقطه ورود اپ
 └─ pages/
     ├─ home_page.dart           # صفحه اصلی و دسته‌بندی ابزارها
     ├─ tcp_client_page.dart
     ├─ tcp_server_page.dart
     ├─ udp_client_page.dart
     ├─ tcp_proxy_page.dart
     ├─ port_scanner_page.dart
     ├─ ping_tool_page.dart
     ├─ traceroute_page.dart
     ├─ arp_scanner_page.dart
     ├─ ip_finder_page.dart
     ├─ dns_lookup_page.dart
     ├─ whois_lookup_page.dart
     ├─ network_dashbord_page.dart
     ├─ wifi_scanner_page.dart
     └─ http_client_page.dart
```

### ⚠️ هشدار

ابزارهای این اپ (پورت اسکنر، ARP اسکنر و ...) فقط باید روی شبکه‌ها و دستگاه‌هایی استفاده شوند که مالک آن‌ها هستید یا اجازه‌ی صریح برای تست آن‌ها را دارید. استفاده از این ابزارها روی شبکه یا دستگاه دیگران بدون اجازه ممکن است طبق قوانین محل شما غیرقانونی باشد.

### سازنده

ساخته‌شده توسط [Ehsan Firuzi](https://github.com/EhsanFiruzi)

### لایسنس

این پروژه تحت [لایسنس MIT](LICENSE) منتشر شده — یعنی هرکسی آزاد است از آن استفاده کند، تغییرش دهد و نسخه‌های تغییریافته را هم منتشر کند.

### مشارکت

مشارکت در پروژه با آغوش باز پذیرفته می‌شود. می‌توانید ریپازیتوری را fork کنید، باگی را رفع کنید یا کد را بهتر کنید و سپس یک pull request ارسال کنید.
