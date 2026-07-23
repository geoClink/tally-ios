//
//  AuthView.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI
import Supabase

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showConfirmationMessage = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false

    private var passwordsMatch: Bool {
        password == confirmPassword
    }

    private var formIsValid: Bool {
        if email.isEmpty || password.isEmpty { return false }
        if isSignUp { return !confirmPassword.isEmpty && passwordsMatch }
        return true
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "timer")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
                .accessibilityHidden(true)

            Text("Tally")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(isSignUp ? "Create your account" : "Sign in to continue")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    #endif
                    .accessibilityLabel("Email address")

                PasswordField(
                    label: "Password",
                    text: $password,
                    isVisible: $showPassword
                )

                if isSignUp {
                    PasswordField(
                        label: "Confirm Password",
                        text: $confirmPassword,
                        isVisible: $showConfirmPassword
                    )

                    if !confirmPassword.isEmpty && !passwordsMatch {
                        Text("Passwords do not match")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
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
            }

            if showConfirmationMessage {
                Text("Check your email to confirm your account, then sign in.")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                Task {
                    await handleAuth()
                }
            } label: {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .font(.headline)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue))
            }
            .disabled(isLoading || !formIsValid)
            .padding(.horizontal)

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

            Spacer()
        }
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
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(uiColor: .systemBackground)))
        )
    }
}
