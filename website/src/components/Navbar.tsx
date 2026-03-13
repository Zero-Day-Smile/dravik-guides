import { motion } from "framer-motion";
import { Mountain, Menu, X, Download, User, LogOut } from "lucide-react";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/hooks/useAuth";
import { useToast } from "@/hooks/use-toast";
import { useNavigate, useLocation } from "react-router-dom";

const Navbar = () => {
  const [open, setOpen] = useState(false);
  const { user, signOut } = useAuth();
  const { toast } = useToast();
  const navigate = useNavigate();
  const location = useLocation();
  const isHome = location.pathname === "/";

  const handleLogout = async () => {
    try {
      await signOut();
      toast({ title: "Logged out", description: "You have been signed out." });
      setOpen(false);
      navigate("/");
    } catch {
      toast({
        title: "Logout failed",
        description: "Please try again.",
        variant: "destructive",
      });
    }
  };

  const navItems = isHome
    ? [
        { label: "Explore", href: "/explore" },
        { label: "Destinations", href: "/explore" },
        { label: "Map", href: "/map" },
        { label: "Features", href: "#features" },
        { label: "Guides", href: "/guides" },
        { label: "Safety", href: "/safety" },
        { label: "Trips", href: "/trips" },
        { label: "Weather", href: "/weather" },
        { label: "Countries", href: "/countries" },
        { label: "Analytics", href: "/analytics" },
        { label: "Emergency", href: "/emergency-guides" },
        { label: "Activity", href: "/activity" },
      ]
    : [
        { label: "Home", href: "/" },
        { label: "Explore", href: "/explore" },
        { label: "Map", href: "/map" },
        { label: "Trips", href: "/trips" },
        { label: "Weather", href: "/weather" },
        { label: "Countries", href: "/countries" },
        { label: "Analytics", href: "/analytics" },
        { label: "Emergency", href: "/emergency-guides" },
        { label: "Activity", href: "/activity" },
        { label: "Features", href: "/#features" },
      ];

  return (
    <motion.nav
      initial={{ opacity: 0, y: -20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6 }}
      className="fixed top-0 left-0 right-0 z-50 glass-card border-b border-border/50"
    >
      <div className="container mx-auto px-6 h-16 flex items-center justify-between">
        <div className="flex items-center gap-2 cursor-pointer" onClick={() => navigate("/")}>
          <Mountain className="w-6 h-6 text-primary" />
          <span className="font-display font-bold text-xl text-foreground">
            DRA<span className="text-gradient-amber">VIK</span>
          </span>
        </div>

        <div className="hidden md:flex items-center gap-8">
          {navItems.map((item) => (
            <a
              key={item.label}
              href={item.href}
              onClick={(e) => {
                if (!item.href.startsWith("#")) {
                  e.preventDefault();
                  navigate(item.href);
                }
              }}
              className="font-body text-sm text-muted-foreground hover:text-foreground transition-colors relative group"
            >
              {item.label}
              <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-primary group-hover:w-full transition-all duration-300" />
            </a>
          ))}
        </div>

        <div className="hidden md:flex items-center gap-3">
          {user ? (
            <>
              <Button
                variant="ghost"
                size="sm"
                className="font-body text-muted-foreground hover:text-foreground"
                onClick={() => navigate("/dashboard")}
              >
                <User className="w-4 h-4 mr-1" />
                Dashboard
              </Button>
              <Button
                variant="ghost"
                size="sm"
                className="font-body text-muted-foreground hover:text-foreground"
                onClick={handleLogout}
              >
                <LogOut className="w-4 h-4 mr-1" />
                Log out
              </Button>
            </>
          ) : (
            <Button
              variant="ghost"
              size="sm"
              className="font-body text-muted-foreground hover:text-foreground"
              onClick={() => navigate("/auth")}
            >
              Sign in
            </Button>
          )}
          <Button
            size="sm"
            className="bg-gradient-amber text-primary-foreground font-display font-semibold shadow-amber hover:opacity-90 transition-opacity"
          >
            <Download className="w-4 h-4 mr-1" />
            Get App
          </Button>
        </div>

        <button onClick={() => setOpen(!open)} className="md:hidden text-foreground">
          {open ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
        </button>
      </div>

      {open && (
        <motion.div
          initial={{ opacity: 0, height: 0 }}
          animate={{ opacity: 1, height: "auto" }}
          className="md:hidden px-6 pb-4 flex flex-col gap-3"
        >
          {navItems.map((item) => (
            <a
              key={item.label}
              href={item.href}
              className="font-body text-sm text-muted-foreground hover:text-foreground transition-colors py-1"
              onClick={(e) => {
                setOpen(false);
                if (!item.href.startsWith("#")) {
                  e.preventDefault();
                  navigate(item.href);
                }
              }}
            >
              {item.label}
            </a>
          ))}
          {user ? (
            <>
              <Button size="sm" variant="outline" className="w-full font-body" onClick={() => { setOpen(false); navigate("/dashboard"); }}>
                Dashboard
              </Button>
              <Button size="sm" variant="outline" className="w-full font-body" onClick={handleLogout}>
                Log out
              </Button>
            </>
          ) : (
            <Button size="sm" variant="outline" className="w-full font-body" onClick={() => { setOpen(false); navigate("/auth"); }}>
              Sign in
            </Button>
          )}
        </motion.div>
      )}
    </motion.nav>
  );
};

export default Navbar;
