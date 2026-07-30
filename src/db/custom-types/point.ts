import { customType } from "drizzle-orm/pg-core";

export interface GeoPoint {
  lat: number;
  lng: number;
}

export const geometryPoint = customType<{
  data: GeoPoint;
  driverData: string;
}>({
  dataType() {
    return "geometry(Point, 4326)";
  },
  toDriver(value: GeoPoint): string {
    return `SRID=4326;POINT(${value.lng} ${value.lat})`;
  },
  fromDriver(value: string): GeoPoint {
    const match = value.match(/POINT\s*\(\s*([-\d.]+)\s+([-\d.]+)\s*\)/i);
    if (!match) {
      throw new Error(`Unable to parse PostGIS point: ${value}`);
    }
    return { lng: parseFloat(match[1]), lat: parseFloat(match[2]) };
  },
});
