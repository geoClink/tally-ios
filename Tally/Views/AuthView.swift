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
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showConfirmationMessage = false
    
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
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    #endif
                    .accessibilityLabel("Email address")
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Password")
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
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            .padding(.horizontal)
            
            Button {
                isSignUp.toggle()
                errorMessage = ""
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
                    // Email confirmation required — no session yet
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
