<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=false; section>
    <#if section = "header">
        Erreur d'authentification
    <#elseif section = "form">
        <div id="kc-error-message" style="text-align:center; padding: 1rem 0;">
            <div style="font-size: 3rem; margin-bottom: 1rem;">⚠️</div>
            <p style="color: #ff6b6b; font-size: 1.1rem; margin-bottom: 1.5rem;">
                ${kcSanitize(message.summary)?no_esc}
            </p>
            <#if skipLink??>
            <#else>
                <#if client?? && client.baseUrl?has_content>
                    <a href="${client.baseUrl}"
                       style="display:inline-block; background:#6364ff; color:#fff; padding:0.6rem 1.5rem;
                              border-radius:8px; text-decoration:none; font-weight:600;">
                        ← Retour à l'application
                    </a>
                </#if>
                <a href="${url.loginUrl}"
                   style="display:inline-block; margin-left:1rem; color:#9baec8; font-size:0.9rem;">
                    Réessayer
                </a>
            </#if>
        </div>
    </#if>
</@layout.registrationLayout>
