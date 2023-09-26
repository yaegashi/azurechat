import NextAuth, { NextAuthOptions } from "next-auth";
import { Provider } from "next-auth/providers";
import AzureADProvider from "next-auth/providers/azure-ad";
import GitHubProvider from "next-auth/providers/github";

const configureIdentityProvider = () => {
  const providers: Array<Provider> = [];

  const adminEmails = process.env.ADMIN_EMAIL_ADDRESS?.split(",").map(email => email.toLowerCase().trim());

  if (process.env.AUTH_GITHUB_ID && process.env.AUTH_GITHUB_SECRET) {
    providers.push(
      GitHubProvider({
        clientId: process.env.AUTH_GITHUB_ID!,
        clientSecret: process.env.AUTH_GITHUB_SECRET!,
        async profile(profile) {
          const newProfile = {
            ...profile,
            isAdmin: adminEmails?.includes(profile.email.toLowerCase())
          }
          return newProfile;
        }
      })
    );
  }

  if (
    process.env.AZURE_AD_CLIENT_ID &&
    process.env.AZURE_AD_CLIENT_SECRET &&
    process.env.AZURE_AD_TENANT_ID
  ) {
    providers.push(
      AzureADProvider({
        clientId: process.env.AZURE_AD_CLIENT_ID!,
        clientSecret: process.env.AZURE_AD_CLIENT_SECRET!,
        tenantId: process.env.AZURE_AD_TENANT_ID!,
        authorization: {
          params: {
            scope: 'email openid profile User.Read'
          }
        },
        async profile(profile) {

          const newProfile = {
            ...profile,
            // throws error without this - unsure of the root cause (https://stackoverflow.com/questions/76244244/profile-id-is-missing-in-google-oauth-profile-response-nextauth)
            id: profile.sub,
            isAdmin: adminEmails?.includes(profile.email.toLowerCase()) || adminEmails?.includes(profile.preferred_username.toLowerCase())
          }
          return newProfile;
        }
      })
    );
  }
  return providers;
};

export const options: NextAuthOptions = {
  secret: process.env.NEXTAUTH_SECRET,
  providers: [...configureIdentityProvider()],
  callbacks: {
    async jwt({token, user, account, profile, isNewUser, session}) {
      if (user?.isAdmin) {
       token.isAdmin = user.isAdmin
      }
      return token
    },
    async session({session, token, user }) {
      session.user.isAdmin = token.isAdmin as string
      return session
    },
    async signIn({ user, account, profile, email, credentials }) {
      console.log("[signIn]")
      console.log(user)
      console.log(account)
      console.log(profile)
      console.log(email)
      console.log(credentials)
      var result = await fetch(
        'https://graph.microsoft.com/v1.0/me/getMemberObjects',
        {
          method: 'POST',
          body: '{"securityEnabledOnly":true}',
          headers: {
            Authorization: `bearer ${account?.access_token}`,
            'Content-Type': 'application/json'
          }
        }
      )
      console.log(result)
      var body = await result.json()
      console.log(body)
      return (body.value as string[]).includes("c0232036-ff8e-4e0c-9832-beb4784f293a")
    }
  },
  session: {
    strategy: "jwt",
  },
};

export const handlers = NextAuth(options);
