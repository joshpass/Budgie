//
//  LoginSignUpView.swift
//  Budgie
//
//  Created by Josh Pasricha on 21/12/22.
//

import SwiftUI
import WebKit

struct LoginSignUpView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    var html = """
    <html>
    <head>
    <meta name="appleid-signin-client-id" content="[CLIENT_ID]">
    <meta name="appleid-signin-scope" content="[SCOPES]">
    <meta name="appleid-signin-redirect-uri" content="[REDIRECT_URI]">
    <meta name="appleid-signin-state" content="[STATE]">
    </head>
    <style>
        .signin-button {
        width: 210px;
        height: 40px;
        }
    </style>
    <body>
    <div id="appleid-signin" class="signin-button" data-color="black" data-border="true" data-type="sign-in"></div>
    <script type="text/javascript" src="https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js"></script>
    </body>
    </html>
    """
    
    var body: some View {
        VStack {
            WebView(html: html)
            Spacer()
            Button {
                PersistenceController.shared.addTestAccount()
                PersistenceController.shared.addTestCategories()
                isLoggedIn = true
            } label: {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(.black)
                    .frame(height: 65)
                    .overlay {
                        Text("CREATE ACCOUNT")
                            .frame(alignment: .center)
                            .padding(.leading, 5)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
            }.padding(.horizontal, 24)
        }
    }
}

struct LoginSignUpView_Previews: PreviewProvider {
    static var previews: some View {
        LoginSignUpView()
    }
}
