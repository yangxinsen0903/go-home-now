import SwiftUI

struct AuthView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var mode: Mode = .login
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""

    enum Mode {
        case login, signup
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("GoHomeNow")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.brandPurple)
                    Text(mode == .login ? "Welcome back" : "Let's find your dog")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                Picker("Mode", selection: $mode) {
                    Text("Log In").tag(Mode.login)
                    Text("Create Account").tag(Mode.signup)
                }
                .pickerStyle(.segmented)

                VStack(spacing: 14) {
                    if mode == .signup {
                        TextField("Name (optional)", text: $name)
                            .textContentType(.name)
                            .textFieldStyle(.roundedBorder)
                    }
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                    SecureField("Password", text: $password)
                        .textContentType(mode == .login ? .password : .newPassword)
                        .textFieldStyle(.roundedBorder)
                }

                if let error = vm.authError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(action: submit) {
                    if vm.isAuthenticating {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text(mode == .login ? "Log In" : "Create Account")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 14)
                .background(canSubmit ? Color.brandPurple : Color.gray.opacity(0.4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(!canSubmit || vm.isAuthenticating)
            }
            .padding(.horizontal, 28)
        }
        .onChange(of: mode) { _, _ in vm.authError = nil }
    }

    private var canSubmit: Bool {
        !email.isEmpty && password.count >= 6
    }

    private func submit() {
        Task {
            if mode == .login {
                await vm.login(email: email, password: password)
            } else {
                await vm.signup(email: email, password: password, name: name.isEmpty ? nil : name)
            }
        }
    }
}
