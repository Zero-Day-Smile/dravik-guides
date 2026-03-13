import { useState } from "react";
import { useAuth } from "@/hooks/useAuth";
import { useNavigate } from "react-router-dom";
import { Mountain, ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { motion } from "framer-motion";
import { useToast } from "@/hooks/use-toast";

const AuthPage = () => {
  const [mode, setMode] = useState<"login" | "signup" | "forgot">("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [displayName, setDisplayName] = useState("");
  const [loading, setLoading] = useState(false);
  const { signIn, signUp, resetPassword } = useAuth();
  const navigate = useNavigate();
  const { toast } = useToast();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      if (mode === "login") {
        const { error } = await signIn(email, password);
        if (error) throw error;
        navigate("/");
      } else if (mode === "signup") {
        const { error } = await signUp(email, password, displayName);
        if (error) throw error;
        toast({ title: "Account created!", description: "Check your email to confirm." });
      } else {
        const { error } = await resetPassword(email);
        if (error) throw error;
        toast({ title: "Reset link sent", description: "Check your email." });
      }
    } catch (err: any) {
      const raw: string = err?.message ?? String(err);
      let friendly = raw;
      if (/load failed|failed to fetch|network|fetch/i.test(raw)) {
        friendly = "Cannot reach the server. The project may be paused — visit your Supabase dashboard to restore it, then try again.";
      } else if (/invalid login|invalid.*credentials/i.test(raw)) {
        friendly = "Incorrect email or password.";
      } else if (/email.*confirm|not confirmed/i.test(raw)) {
        friendly = "Please confirm your email before signing in.";
      } else if (/already registered|user.*exists/i.test(raw)) {
        friendly = "An account with this email already exists. Try signing in instead.";
      } else if (/weak.*password|password.*short/i.test(raw)) {
        friendly = "Password must be at least 6 characters.";
      }
      toast({ title: "Error", description: friendly, variant: "destructive" });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-background flex items-center justify-center px-6">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="w-full max-w-md"
      >
        <button onClick={() => navigate("/")} className="flex items-center gap-2 text-muted-foreground hover:text-foreground mb-8 font-body text-sm transition-colors">
          <ArrowLeft className="w-4 h-4" /> Back to home
        </button>

        <div className="glass-card rounded-2xl p-8">
          <div className="flex items-center gap-2 mb-6">
            <Mountain className="w-6 h-6 text-primary" />
            <span className="font-display font-bold text-xl text-foreground">
              DRA<span className="text-gradient-amber">VIK</span>
            </span>
          </div>

          <h1 className="font-display font-bold text-2xl text-foreground mb-2">
            {mode === "login" ? "Welcome back" : mode === "signup" ? "Join the expedition" : "Reset password"}
          </h1>
          <p className="font-body text-sm text-muted-foreground mb-6">
            {mode === "login" ? "Sign in to your adventure account" : mode === "signup" ? "Create your explorer profile" : "We'll send you a reset link"}
          </p>

          <form onSubmit={handleSubmit} className="space-y-4">
            {mode === "signup" && (
              <Input
                placeholder="Display name"
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                className="bg-muted border-border font-body"
                required
              />
            )}
            <Input
              type="email"
              placeholder="Email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="bg-muted border-border font-body"
              required
            />
            {mode !== "forgot" && (
              <Input
                type="password"
                placeholder="Password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="bg-muted border-border font-body"
                required
                minLength={6}
              />
            )}
            <Button type="submit" disabled={loading} className="w-full bg-gradient-amber text-primary-foreground font-display font-semibold shadow-amber">
              {loading ? "Loading..." : mode === "login" ? "Sign In" : mode === "signup" ? "Create Account" : "Send Reset Link"}
            </Button>
          </form>

          <div className="mt-4 space-y-2 text-center">
            {mode === "login" && (
              <>
                <button onClick={() => setMode("forgot")} className="font-body text-sm text-primary hover:underline block w-full">
                  Forgot password?
                </button>
                <p className="font-body text-sm text-muted-foreground">
                  Don't have an account?{" "}
                  <button onClick={() => setMode("signup")} className="text-primary hover:underline">Sign up</button>
                </p>
              </>
            )}
            {mode === "signup" && (
              <p className="font-body text-sm text-muted-foreground">
                Already have an account?{" "}
                <button onClick={() => setMode("login")} className="text-primary hover:underline">Sign in</button>
              </p>
            )}
            {mode === "forgot" && (
              <button onClick={() => setMode("login")} className="font-body text-sm text-primary hover:underline">
                Back to sign in
              </button>
            )}
          </div>
        </div>
      </motion.div>
    </div>
  );
};

export default AuthPage;
