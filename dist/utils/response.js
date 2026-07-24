export function sendSuccess(res, data, statusCode = 200) {
    return res.status(statusCode).json({ success: true, data });
}
export function sendError(res, statusCode, error) {
    return res.status(statusCode).json({ success: false, error });
}
//# sourceMappingURL=response.js.map