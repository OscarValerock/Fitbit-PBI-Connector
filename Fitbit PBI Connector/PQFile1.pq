    let

        authorize_uri = "https://www.fitbit.com/oauth2/authorize",
        redirect_uri = "https://oauth.powerbi.com/views/oauthredirect.html",
        client_id = "22C2QH",

        authorizeUrl = authorize_uri & "?" & Uri.BuildQueryString([
            response_type = "token",
            client_id = client_id,
            redirect_uri = redirect_uri,
            scope = "profile activity sleep weight",
            expires_in= "604800",
           // state = state,
            prompt = "login"
        ])
    in
        authorize_uri