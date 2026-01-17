interface LogoProps {
  variant?: 'full' | 'icon' | 'text';
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
}

export function Logo({ variant = 'full', size = 'md', className = '' }: LogoProps) {
  const sizes = {
    sm: { container: 'h-8', icon: 32, text: 'text-lg' },
    md: { container: 'h-12', icon: 48, text: 'text-2xl' },
    lg: { container: 'h-16', icon: 64, text: 'text-3xl' },
    xl: { container: 'h-24', icon: 96, text: 'text-5xl' },
  };

  const currentSize = sizes[size];

  const LogoIcon = ({ size: iconSize }: { size: number }) => {
    const borderRadius = iconSize * 0.28;
    const fontSize = iconSize * 0.8; // Even larger "d"
    
    return (
      <svg
        width={iconSize}
        height={iconSize}
        viewBox="0 0 100 100"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <defs>
          {/* More striking background gradient */}
          <linearGradient id="bgGradient" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" className="[stop-color:var(--primary-light,var(--primary))]" />
            <stop offset="100%" className="[stop-color:var(--primary-dark,var(--primary))]" />
          </linearGradient>
        </defs>
        
        {/* Rounded square background with striking gradient */}
        <rect 
          x="0" 
          y="0" 
          width="100" 
          height="100" 
          rx={borderRadius} 
          fill="url(#bgGradient)"
        />
        
        {/* The lowercase 'd' in white */}
        <text
          x="50"
          y="54"
          textAnchor="middle"
          dominantBaseline="central"
          className="fill-primary-foreground"
          style={{
            fontFamily: 'DM Sans, sans-serif',
            fontWeight: 700,
            fontSize: `${fontSize}px`,
            letterSpacing: '-0.02em',
          }}
        >
          d
        </text>
      </svg>
    );
  };

  if (variant === 'icon') {
    return (
      <div className={`inline-flex items-center justify-center ${className}`}>
        <LogoIcon size={currentSize.icon} />
      </div>
    );
  }

  if (variant === 'text') {
    return (
      <div className={`inline-flex items-center ${className}`}>
        <span 
          className={`${currentSize.text} text-primary tracking-tight`}
          style={{ fontFamily: 'DM Sans, sans-serif', fontWeight: 600 }}
        >
          ivvy
        </span>
      </div>
    );
  }

  return (
    <div className={`inline-flex items-center gap-2.5 ${currentSize.container} ${className}`}>
      <LogoIcon size={currentSize.icon} />
      <span 
        className={`${currentSize.text} text-primary tracking-tight`}
        style={{ fontFamily: 'DM Sans, sans-serif', fontWeight: 600 }}
      >
        ivvy
      </span>
    </div>
  );
}