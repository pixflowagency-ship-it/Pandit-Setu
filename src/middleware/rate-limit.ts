import rateLimit from "express-rate-limit";

/** OTP send — tight: 5 req / min / IP */
export const otpSendLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      code: "RATE_LIMITED",
      message: "Too many OTP requests — try again in a minute",
    },
  },
});

/** OTP verify — moderate: 10 req / min / IP */
export const otpVerifyLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      code: "RATE_LIMITED",
      message: "Too many verification attempts — try again in a minute",
    },
  },
});

/** General API — 100 req / min / IP */
export const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      code: "RATE_LIMITED",
      message: "Too many requests — please slow down",
    },
  },
});

/** Strict — 30 req / min / IP for mutations */
export const strictLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      code: "RATE_LIMITED",
      message: "Too many mutation requests — please slow down",
    },
  },
});

/** Nearby — 20 req / min / IP for geospatial queries */
export const nearbyLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      code: "RATE_LIMITED",
      message: "Too many search requests — please slow down",
    },
  },
});

/** Places API — 5 req / min / IP for geospatial queries */
export const placesApiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      code: "RATE_LIMITED",
      message: "Too many Places API requests — please slow down",
    },
  },
});
