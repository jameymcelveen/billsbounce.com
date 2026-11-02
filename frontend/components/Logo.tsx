import React from 'react';

export const BrandLogo = () => (
<svg xmlns="http://w3.org" viewBox="0 0 1000 650" className="w-full h-auto">
<defs>
<radialGradient id="spaceBg" cx="50%" cy="30%" r="75%">
<stop offset="0%" stop-color="#111424" />
<stop offset="100%" stop-color="#020305" />
</radialGradient>
<filter id="thickShadow">
<feDropShadow dx="0" dy="8" stdDeviation="0" flood-color="#1e3a8a" />
</filter>
</defs>
<rect width="1000" height="650" fill="url(#spaceBg)" rx="16" />
<g transform="translate(50, 280)" filter="url(#thickShadow)" fontFamily="Impact, sans-serif" fontSize="115" fontWeight="900">
<text x="100" y="110" fill="#ef4444" stroke="#ffffff" strokeWidth="4">BILL'S</text>
<text x="460" y="110" fill="#3b82f6" stroke="#ffffff" strokeWidth="4">BOUNCE</text>
</g>
</svg>
);