import { Mountain } from "lucide-react";

const links = {
  Product: ["Features", "Pricing", "Downloads"],
  Learn: ["Guides", "Documentation", "Community"],
  Company: ["About", "Blog", "Careers"],
  Legal: ["Privacy", "Terms", "Contact"],
};

const Footer = () => {
  return (
    <footer className="border-t border-border pt-16 pb-8">
      <div className="container mx-auto px-6">
        <div className="grid grid-cols-2 md:grid-cols-5 gap-10 mb-12">
          <div className="col-span-2 md:col-span-1">
            <div className="flex items-center gap-2 mb-4">
              <Mountain className="w-5 h-5 text-primary" />
              <span className="font-display font-bold text-foreground">
                DRA<span className="text-gradient-amber">VIK</span>
              </span>
            </div>
            <p className="font-body text-sm text-muted-foreground leading-relaxed">
              Your expedition companion. Built for the wild.
            </p>
          </div>
          {Object.entries(links).map(([category, items]) => (
            <div key={category}>
              <h4 className="font-display font-semibold text-foreground mb-4 text-sm">
                {category}
              </h4>
              <ul className="space-y-3">
                {items.map((item) => (
                  <li key={item}>
                    <a
                      href="#"
                      className="font-body text-sm text-muted-foreground hover:text-foreground transition-colors"
                    >
                      {item}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
        <div className="border-t border-border pt-6 flex flex-col md:flex-row items-center justify-between gap-4">
          <p className="font-body text-sm text-muted-foreground">
            © 2026 Dravik. Built for the wild.
          </p>
          <p className="font-body text-xs text-muted-foreground">
            All rights reserved.
          </p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
