export interface GeoPoint {
    lat: number;
    lng: number;
}
/**
 * PostGIS geometry(Point, 4326) mapped to { lat, lng } in application code.
 */
export declare const geometryPoint: {
    (): import("drizzle-orm/pg-core").PgCustomColumnBuilder<{
        name: "";
        dataType: "custom";
        columnType: "PgCustomColumn";
        data: GeoPoint;
        driverParam: string;
        enumValues: undefined;
    }>;
    <TConfig extends Record<string, any>>(fieldConfig?: TConfig | undefined): import("drizzle-orm/pg-core").PgCustomColumnBuilder<{
        name: "";
        dataType: "custom";
        columnType: "PgCustomColumn";
        data: GeoPoint;
        driverParam: string;
        enumValues: undefined;
    }>;
    <TName extends string>(dbName: TName, fieldConfig?: unknown): import("drizzle-orm/pg-core").PgCustomColumnBuilder<{
        name: TName;
        dataType: "custom";
        columnType: "PgCustomColumn";
        data: GeoPoint;
        driverParam: string;
        enumValues: undefined;
    }>;
};
//# sourceMappingURL=point.d.ts.map