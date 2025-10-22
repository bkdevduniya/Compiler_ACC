// Empty statements in strange places
for (;;);           // Just semicolon
if (x); else ;      // Empty both branches

// Declaration as statement// Uniform initialization

// Complex for loop initializers
for (auto [a,b] = getPair(); a < b; a++)  // Structured binding