import { customType } from "drizzle-orm/pg-core";
/**
 * PostGIS geometry(Point, 4326) mapped to { lat, lng } in application code.
 */
export const geometryPoint = customType({
    dataType() {
        return "geometry(Point, 4326)";
    },
    toDriver(value) {
        return `SRID=4326;POINT(${value.lng} ${value.lat})`;
    },
    fromDriver(value) {
        const match = value.match(/POINT\s*\(\s*([-\d.]+)\s+([-\d.]+)\s*\)/i);
        if (!match) {
            throw new Error(`Unable to parse PostGIS point: ${value}`);
        }
        return { lng: parseFloat(match[1]), lat: parseFloat(match[2]) };
    },
});
//# sourceMappingURL=point.js.map