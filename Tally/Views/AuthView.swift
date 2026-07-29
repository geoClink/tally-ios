//
//  AuthView.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI
import Supabase
import AuthenticationServices
import CryptoKit
import GoogleSignIn

struct AuthView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showConfirmationMessage = false
    @State private var showResetMessage = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var currentNonce: String?

    private var passwordsMatch: Bool {
        password == confirmPassword
    }

    private var formIsValid: Bool {
        if email.isEmpty || password.isEmpty { return false }
        if isSignUp { return !confirmPassword.isEmpty && passwordsMatch }
        return true
    }

    var body: some View {
        ZStack {
            // Decorative background circles
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.22))
                        .frame(width: geo.size.width * 0.85)
                        .blur(radius: 90)
                        .offset(x: geo.size.width * 0.35, y: -geo.size.height * 0.08)

                    Circle()
                        .fill(Color.indigo.opacity(0.16))
                        .frame(width: geo.size.width * 0.7)
                        .blur(radius: 75)
                        .offset(x: -geo.size.width * 0.3, y: geo.size.height * 0.5)
                }
            }
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: 0) {
                // Brand header
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 90, height: 90)
                        Circle()
                            .stroke(Color.blue.opacity(0.25), lineWidth: 1.5)
                            .frame(width: 90, height: 90)
                        Image(systemName: "timer")
                            .font(.system(size: 38, weight: .light))
                            .foregroundStyle(.blue)
                    }
                    .padding(.bottom, 4)
                    .accessibilityHidden(true)

                    Text("Tally")
                        .font(.system(size: 34, weight: .bold))

                    Text(isSignUp ? "Create your account" : "Sign in to continue")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 64)
                .padding(.bottom, 32)

                // Input fields
                VStack(spacing: 10) {
                    StyledTextField("Email", text: $email)
                        #if os(iOS)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        #endif
                        .textContentType(.emailAddress)
                        .accessibilityLabel("Email address")

                    PasswordField(label: "Password", text: $password, isVisible: $showPassword)

                    if isSignUp {
                        PasswordField(label: "Confirm Password", text: $confirmPassword, isVisible: $showConfirmPassword)

                        if !confirmPassword.isEmpty && !passwordsMatch {
                            Text("Passwords do not match")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                if showConfirmationMessage {
                    Text("Check your email to confirm your account, then sign in.")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                if showResetMessage {
                    Text("Password reset link sent — check your email.")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                // Primary action
                Button {
                    Task { await handleAuth() }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(isSignUp ? "Create Account" : "Sign In")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isLoading || !formIsValid)
                .padding(.horizontal)
                .padding(.top, 16)

                VStack(spacing: 10) {
                    Button {
                        isSignUp.toggle()
                        errorMessage = ""
                        confirmPassword = ""
                        showPassword = false
                        showConfirmPassword = false
                    } label: {
                        Text(isSignUp ? "Already have an account? Sign in" : "Don't have an account? Sign up")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }

                    if !isSignUp {
                        Button {
                            Task { await handleForgotPassword() }
                        } label: {
                            Text("Forgot password?")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 14)

                // Divider
                HStack(spacing: 12) {
                    Rectangle().frame(height: 0.5).foregroundStyle(Color(.systemGray4))
                    Text("or").font(.caption).foregroundStyle(.secondary)
                    Rectangle().frame(height: 0.5).foregroundStyle(Color(.systemGray4))
                }
                .padding(.horizontal)
                .padding(.vertical, 20)

                // Social sign-in — both buttons at Google's native 44pt height
                VStack(spacing: 12) {
                    Button {
                        Task { await handleGoogleSignIn() }
                    } label: {
                        Image("GoogleSignInButton")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 44)
                    }
                    .disabled(isLoading)

                    SignInWithAppleButton(.signIn) { request in
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    } onCompletion: { result in
                        Task { await handleAppleSignIn(result) }
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .whiteOutline : .black)
                    .frame(width: 188, height: 44)
                    .cornerRadius(4)
                    .disabled(isLoading)
                    .id(colorScheme)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)

                Spacer().frame(height: 48)
            }
        }
        } // ZStack
    }

    private func handleGoogleSignIn() async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to present Google Sign-In."
            return
        }
        isLoading = true
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Unable to get ID token from Google."
                isLoading = false
                return
            }
            let accessToken = result.user.accessToken.tokenString
            try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .google, idToken: idToken, accessToken: accessToken)
            )
            NotificationCenter.default.post(name: .supabaseAuthStateChanged, object: nil)
        } catch {
            if (error as? GIDSignInError)?.code != .canceled {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                errorMessage = "Unable to complete Apple Sign In. Please try again."
                return
            }
            isLoading = true
            do {
                try await supabase.auth.signInWithIdToken(
                    credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
                )
                // Apple only sends fullName on first sign-in — save it to user metadata immediately
                if let fullName = credential.fullName {
                    let formatter = PersonNameComponentsFormatter()
                    let displayName = formatter.string(from: fullName)
                    if !displayName.isEmpty {
                        _ = try? await supabase.auth.update(user: .init(data: ["full_name": .string(displayName)]))
                    }
                }
                NotificationCenter.default.post(name: .supabaseAuthStateChanged, object: nil)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let hashedData = SHA256.hash(data: Data(input.utf8))
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func handleForgotPassword() async {
        guard !email.isEmpty else {
            errorMessage = "Enter your email address first."
            return
        }
        isLoading = true
        errorMessage = ""
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            showResetMessage = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func handleAuth() async {
        isLoading = true
        errorMessage = ""

        do {
            if isSignUp {
                let response = try await supabase.auth.signUp(
                    email: email,
                    password: password
                )
                if response.session == nil {
                    showConfirmationMessage = true
                    isLoading = false
                    return
                }
            } else {
                try await supabase.auth.signIn(
                    email: email,
                    password: password
                )
            }
            NotificationCenter.default.post(name: .supabaseAuthStateChanged, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

private struct StyledTextField: View {
    let label: String
    @Binding var text: String

    init(_ label: String, text: Binding<String>) {
        self.label = label
        self._text = text
    }

    var body: some View {
        TextField(label, text: $text)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(uiColor: .systemBackground)))
            )
    }
}

private struct PasswordField: View {
    let label: String
    @Binding var text: String
    @Binding var isVisible: Bool

    var body: some View {
        HStack {
            Group {
                if isVisible {
                    TextField(label, text: $text)
                        #if os(iOS)
                        .autocapitalization(.none)
                        #endif
                } else {
                    SecureField(label, text: $text)
                }
            }
            .accessibilityLabel(label)

            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel(isVisible ? "Hide password" : "Show password")
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(uiColor: .systemBackground)))
        )
    }
}
