import SwiftUI
import UserNotifications
import BackgroundTasks

@main
struct NamazVaktiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var state = AppState()
    @Environment(\.scenePhase) private var scenePhase

    nonisolated static let refreshTaskID = "com.kadiratilgan.namazvakti.refresh"

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(state)
                .environment(\.locale, Loc.locale)
                .preferredColorScheme(state.colorScheme)
                .tint(Theme.accent)
                .id(state.language)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                state.refreshAll()
                Self.scheduleRefresh()
            }
        }
        .backgroundTask(.appRefresh(Self.refreshTaskID)) {
            await MainActor.run {
                let s = AppState()
                s.reschedule()
                s.syncLiveActivity()
                SharedStore.reloadWidgets()
            }
            Self.scheduleRefresh()
        }
    }

    nonisolated static func scheduleRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskID)
        request.earliestBeginDate = Date().addingTimeInterval(3 * 3600)
        try? BGTaskScheduler.shared.submit(request)
    }
}

/// Handles the "Prayed" and "Snooze" buttons on notifications.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        NotificationService.registerCategories()
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let info = response.notification.request.content.userInfo
        switch response.actionIdentifier {
        case NotificationService.Action.prayed:
            if let raw = info["kind"] as? String, let kind = PrayerKind(rawValue: raw),
               let dayKey = info["day"] as? String, let day = Self.date(fromKey: dayKey) {
                SharedStore.setPrayed(kind, on: day, true)
                NotificationService.removeEndWarning(kind: kind, day: day)
            }
        case NotificationService.Action.snooze:
            NotificationService.snooze(response.notification.request.content)
        default:
            break
        }
        completionHandler()
    }

    static func date(fromKey key: String) -> Date? {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: key)
    }
}

struct RootView: View {
    @EnvironmentObject private var state: AppState
    @State private var tab = 0

    var body: some View {
        if state.onboarded {
            TabView(selection: $tab) {
                VakitlerView()
                    .tabItem { Label(Loc.s("Vakitler"), systemImage: "clock") }.tag(0)
                TakvimView()
                    .tabItem { Label(Loc.s("Takvim"), systemImage: "calendar") }.tag(1)
                KibleView()
                    .tabItem { Label(Loc.s("Kıble"), systemImage: "location.north.circle") }.tag(2)
                KesfetView()
                    .tabItem { Label(Loc.s("Keşfet"), systemImage: "square.grid.2x2") }.tag(3)
                AyarlarView()
                    .tabItem { Label(Loc.s("Ayarlar"), systemImage: "slider.horizontal.3") }.tag(4)
            }
            .onOpenURL { url in
                // namazvakti://takip from the tracking widget opens Discover (where tracking lives)
                if url.host == "takip" { tab = 3 }
            }
        } else {
            OnboardingView()
        }
    }
}

/// First launch: explains why location and notifications are needed, then asks for them.
struct OnboardingView: View {
    @EnvironmentObject private var state: AppState
    @State private var step = 0

    var body: some View {
        ZStack {
            Theme.heroGradient.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                AppBadge(size: 96)
                Text(Loc.s("Namaz Vakti")).font(.largeTitle.bold()).foregroundStyle(Theme.cream)
                Group {
                    if step == 0 {
                        Text(Loc.s("Vakitleri ve kıbleyi bulunduğun yere göre hesaplamak için konumuna ihtiyacımız var. Konumun cihazından çıkmaz."))
                    } else {
                        Text(Loc.s("Vakit girdiğinde ve vakit çıkmadan önce haber verebilmemiz için bildirimlere izin ver."))
                    }
                }
                .font(.body).multilineTextAlignment(.center).foregroundStyle(Theme.goldText).padding(.horizontal, 32)
                Spacer()
                Button {
                    if step == 0 {
                        state.location.requestPermission()
                        step = 1
                    } else {
                        Task {
                            _ = await NotificationService.requestAuthorization()
                            await MainActor.run {
                                state.onboarded = true
                                state.refreshAll()
                            }
                        }
                    }
                } label: {
                    Text(step == 0 ? Loc.s("Konuma izin ver") : Loc.s("Bildirimlere izin ver"))
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Theme.gold, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(Theme.deep)
                }
                .padding(.horizontal, 24)
                Button(Loc.s("Şimdi değil")) {
                    if step == 0 { step = 1 } else { state.onboarded = true; state.refreshAll() }
                }
                .foregroundStyle(Theme.cream)
                .padding(.bottom, 24)
            }
        }
    }
}
