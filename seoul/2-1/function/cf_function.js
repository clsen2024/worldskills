function handler(event) {
    const request = event.request;
    const host = request.headers.host.value;
    const uri = request.uri;

    if (uri !== "/index.html") {
        const index = `https://${host}/index.html`;
        return {
            statusCode: 301,
            statusDescription: "Moved Permanently",
            headers: {
                "location": { "value": index },
            },
        };
    }

    return request;
}