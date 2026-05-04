import SwiftUI

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Profile Gradient
private let profileGradient = LinearGradient(
    colors: [Color(hex: "084CDD"), Color(hex: "2673FF")],
    startPoint: .top,
    endPoint: .bottom
)

// MARK: - Profile Menu Row
struct ProfileMenuRow: View {
    let title: String
    let systemIconName: String
    var titleColor: Color = Color(hex: "373737")
    var iconColor: Color = Color(hex: "161616")
    var showChevron: Bool = true

    var body: some View {
        HStack(spacing: 4) {
            if showChevron {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "373737"))
            }
            Spacer()
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(titleColor)
                .multilineTextAlignment(.trailing)
            Image(systemName: systemIconName)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 20, height: 20)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 20)
    }
}

// MARK: - Profile Header Shape
struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - 30))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - 30),
            control: CGPoint(x: rect.width / 2, y: rect.height + 10)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - ProfileView
struct ProfileView: View {
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    menuSection
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
            .background(Color.white)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .alert("تسجيل الخروج", isPresented: $showLogoutAlert) {
            Button("تأكيد", role: .destructive) {}
            Button("إلغاء", role: .cancel) {}
        } message: {
            Text("هل تريد تسجيل الخروج؟")
        }
        .alert("حذف الحساب", isPresented: $showDeleteAlert) {
            Button("حذف", role: .destructive) {}
            Button("إلغاء", role: .cancel) {}
        } message: {
            Text("هل أنت متأكد أنك تريد حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء.")
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        ZStack(alignment: .bottom) {
            profileGradient
                .clipShape(WaveShape())

            VStack(spacing: 16) {
                // Nav title
                Text("ملفي الشخصي")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)

                // Avatar + name + rating
                VStack(spacing: 4) {
                    AsyncImage(url: URL(string: "https://api.builder.io/api/v1/image/assets/TEMP/16aa8641d502f067077cd8d375d7ccd3e058936d?width=248")) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 124, height: 124)
                    .clipShape(Circle())

                    Text("علي الاغا")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "101010"))
                        .padding(.top, 4)

                    HStack(spacing: 4) {
                        Image(systemName: "star.leadinghalf.filled")
                            .foregroundColor(Color(hex: "FFCB03"))
                            .font(.system(size: 14))
                        Text("4.5")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "373737"))
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Menu
    private var menuSection: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: Text("بياناتي الاساسية")) {
                ProfileMenuRow(title: "بياناتي الاساسية", systemIconName: "person")
            }
            .buttonStyle(.plain)

            Divider().foregroundColor(Color(hex: "CFCFCF")).padding(.horizontal, 8)

            NavigationLink(destination: Text("بياناتي كبائع")) {
                ProfileMenuRow(title: "بياناتي كبائع", systemIconName: "person.badge.shield.checkmark")
            }
            .buttonStyle(.plain)

            Divider().foregroundColor(Color(hex: "CFCFCF")).padding(.horizontal, 8)

            NavigationLink(destination: Text("المنتجات المتاحة للبيع")) {
                ProfileMenuRow(title: "المنتجات المتاحة للبيع", systemIconName: "shippingbox")
            }
            .buttonStyle(.plain)

            Divider().foregroundColor(Color(hex: "CFCFCF")).padding(.horizontal, 8)

            NavigationLink(destination: Text("المنتجات المُباعة")) {
                ProfileMenuRow(title: "المنتجات المُباعة", systemIconName: "shippingbox.and.arrow.backward")
            }
            .buttonStyle(.plain)

            Divider().foregroundColor(Color(hex: "CFCFCF")).padding(.horizontal, 8)

            Button {
                showLogoutAlert = true
            } label: {
                ProfileMenuRow(
                    title: "تسجيل الخروج",
                    systemIconName: "rectangle.portrait.and.arrow.right",
                    titleColor: Color(hex: "101010"),
                    iconColor: Color(hex: "161616"),
                    showChevron: false
                )
            }
            .buttonStyle(.plain)

            Divider().foregroundColor(Color(hex: "CFCFCF")).padding(.horizontal, 8)

            Button {
                showDeleteAlert = true
            } label: {
                ProfileMenuRow(
                    title: "حذف الحساب",
                    systemIconName: "person.badge.minus",
                    titleColor: Color(hex: "F44336"),
                    iconColor: Color(hex: "F44336"),
                    showChevron: false
                )
            }
            .buttonStyle(.plain)
        }
        .background(Color.white)
        .padding(.top, 8)
    }
}

// MARK: - Main Tab Container
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ProfileView()
                .tabItem {
                    Label("ملفي", systemImage: selectedTab == 0 ? "person.fill" : "person")
                }
                .tag(0)

            Text("المفضلة")
                .tabItem {
                    Label("المفضلة", systemImage: "heart")
                }
                .tag(1)

            Text("المتجر")
                .tabItem {
                    Label("إضافة", systemImage: "storefront")
                }
                .tag(2)

            Text("الرئيسية")
                .tabItem {
                    Label("الرئيسية", systemImage: "house")
                }
                .tag(3)
        }
        .accentColor(Color(hex: "084CDD"))
        .environment(\.layoutDirection, .rightToLeft)
    }
}

// MARK: - Preview
#Preview("Profile") {
    MainTabView()
}
