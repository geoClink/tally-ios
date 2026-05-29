//
//  SupabaseManager.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://fcmfuxoblbtxigknwhpz.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZjbWZ1eG9ibGJ0eGlna253aHB6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk5OTQ4MzQsImV4cCI6MjA5NTU3MDgzNH0.YFH0CVGnLAW4ufdj04aAc2e4CZeGxnNsyAfo3n40VPM"
)
