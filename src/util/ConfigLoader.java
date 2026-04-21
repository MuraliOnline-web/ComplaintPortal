package util;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

/**
 * ConfigLoader - Loads configuration from environment variables or config.properties
 * Prioritizes environment variables over file-based config for security
 */
public class ConfigLoader {
    private static Properties properties = new Properties();

    static {
        try {
            // Try to load from config.properties if it exists (for local development)
            try (InputStream input = ConfigLoader.class
                    .getClassLoader()
                    .getResourceAsStream("config.properties")) {
                if (input != null) {
                    properties.load(input);
                }
            } catch (IOException e) {
                System.err.println("config.properties not found - using environment variables only");
            }
        } catch (Exception e) {
            System.err.println("Error loading configuration: " + e.getMessage());
        }
    }

    /**
     * Get configuration value from environment variable first, then from properties file
     * @param key Configuration key
     * @param defaultValue Fallback value if not found
     * @return Configuration value
     */
    public static String get(String key, String defaultValue) {
        // Priority: Environment variables > properties file > default value
        String envValue = System.getenv(toEnvVarName(key));
        if (envValue != null && !envValue.trim().isEmpty()) {
            return envValue.trim();
        }

        String sysValue = System.getProperty(key);
        if (sysValue == null || sysValue.trim().isEmpty()) {
            // Allow -DSMTP_USER style as well as -Dsmtp.user.
            sysValue = System.getProperty(toEnvVarName(key));
        }
        if (sysValue != null && !sysValue.trim().isEmpty()) {
            return sysValue.trim();
        }

        String propValue = properties.getProperty(key);
        if (propValue != null && !propValue.trim().isEmpty()) {
            return propValue.trim();
        }

        return defaultValue;
    }

    /**
     * Convert property key to environment variable name (e.g., db.url -> DB_URL)
     */
    private static String toEnvVarName(String key) {
        return key.toUpperCase().replace(".", "_");
    }

    // Convenience methods for common config
    public static String getDbUrl() {
        return get("db.url", "");
    }

    public static String getDbUser() {
        return get("db.user", "");
    }

    public static String getDbPassword() {
        return get("db.password", "");
    }

    public static String getSmtpHost() {
        return get("smtp.host", "smtp.gmail.com");
    }

    public static String getSmtpPort() {
        return get("smtp.port", "587");
    }

    public static String getSmtpUser() {
        return get("smtp.user", "");
    }

    public static String getSmtpPassword() {
        return get("smtp.password", "");
    }
}
