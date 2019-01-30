<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.Settings"
    CodeBehind="Settings.aspx.vb" %>

<%@ Register TagPrefix="control1" TagName="SkinSettings" Src="Controls\SkinSettings.ascx" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <script src="Scripts/jquery-3.1.1.min.js" type="text/javascript"></script>
    <script src="Scripts/TabPages.js?v=8.1" type="text/javascript"></script>
    <script type="text/javascript">
        function chkSaml_OnClick() {
            var disableNodes = !document.getElementById('<%=chkSaml.ClientID %>').checked;

            document.getElementById('<%=chkCreateUsers.ClientID %>').disabled = disableNodes;
            document.getElementById('<%=txtIssuer.ClientID %>').disabled = disableNodes;
            document.getElementById('<%=txtManageEntityId.ClientID %>').disabled = disableNodes;
            document.getElementById('<%=txtProduceEntityId.ClientID %>').disabled = disableNodes;
            document.getElementById('<%=txtLoginUrl.ClientID %>').disabled = disableNodes;
            document.getElementById('<%=txtLogoutUrl.ClientID %>').disabled = disableNodes;
            document.getElementById('<%=chkCertificateThumbprint.ClientID %>').disabled = disableNodes;
            document.getElementById('<%=chkCertificateUpload.ClientID %>').disabled = disableNodes;
            document.getElementById('<%=txtCertThumbprint.ClientID %>').disabled = disableNodes;
            document.getElementById('<%=filCertificate.ClientID %>').disabled = disableNodes;
            document.getElementById('<%=chkSamlLog.ClientID %>').disabled = disableNodes;
        }
        function certificateChanged() {
            if (document.getElementById('<%=chkCertificateThumbprint.ClientID %>').checked) {
                document.getElementById('<%=lblThumbprint.ClientID %>').style.display = '';
                document.getElementById('<%=txtCertThumbprint.ClientID %>').style.display = '';
                document.getElementById('<%=filCertificate.ClientID %>').style.display = 'none';
            }
            else {
                document.getElementById('<%=lblThumbprint.ClientID %>').style.display = 'none';
                document.getElementById('<%=txtCertThumbprint.ClientID %>').style.display = 'none';
                document.getElementById('<%=filCertificate.ClientID %>').style.display = '';
            }

        }
        function spCertificateChanged() {
            if (document.getElementById('<%=chkSpCertificateThumbprint.ClientID %>').checked) {
                document.getElementById('<%=lblSpThumbprint.ClientID %>').style.display = '';
                document.getElementById('<%=txtSpCertThumbprint.ClientID %>').style.display = '';
                document.getElementById('<%=filSpCertificate.ClientID %>').style.display = 'none';
            }
            else {
                document.getElementById('<%=lblSpThumbprint.ClientID %>').style.display = 'none';
                document.getElementById('<%=txtSpCertThumbprint.ClientID %>').style.display = 'none';
                document.getElementById('<%=filSpCertificate.ClientID %>').style.display = '';
            }

        }
        function chkMinPasswordLength_OnClick() {
            var disable = !document.getElementById('<%=chkMinPasswordLength.ClientID%>').checked;
            document.getElementById('<%=txtMinPasswordLength.ClientID%>').disabled = disable;
        }
        function chkInvalidPasswordAttempts_OnClick() {
            var disable = !document.getElementById('<%=chkInvalidPasswordAttempts.ClientID%>').checked;
            document.getElementById('<%=txtInvalidPasswordAttempts.ClientID%>').disabled = disable;
        }
        function chkPasswordHistoryCount_OnClick() {
            var disable = !document.getElementById('<%=chkPasswordHistoryCount.ClientID%>').checked;
            document.getElementById('<%=txtPasswordHistoryCount.ClientID%>').disabled = disable;
        }
        function chkMaximumPasswordAge_OnClick() {
            var disable = !document.getElementById('<%=chkMaximumPasswordAge.ClientID%>').checked;
            document.getElementById('<%=txtMaximumPasswordAge.ClientID%>').disabled = disable;
        }
        function validateGenerationDays(sender, args) {
            validateNumeric(sender, args);
            if (!args.IsValid) {
                sender.innerHTML = '<%=Resources.Strings.NumericType%>';
                return;
            }
            <% If Intelledox.Controller.LicenseController.HasTransactionalLicense(Infiniti.MvcControllers.UserSettings.BusinessUnit) Then %>
            if (args.Value < 90) {
                sender.innerHTML = '<%=String.Format(Resources.Strings.GreaterThanNumber, "90")%>';
                args.IsValid = false;
            }
            <% End If %>
        }
        function validateNumeric(sender, args) {
            args.IsValid = true;
            if (!$.isNumeric(args.Value)) {
                args.IsValid = false;
            }
            else if (args.Value < 0) {
                args.IsValid = false;
            }
        }
        function validateNumericGreaterThanZero(sender, args) {
            args.IsValid = true;
            if (!$.isNumeric(args.Value)) {
                args.IsValid = false;
            }
            else if (args.Value <= 0) {
                args.IsValid = false;
            }
        }
        $(document).ready(function () {
            var showChar = 200;
            var ellipsestext ="<%=Resources.Strings.Ellipse%>";
            var moretext = "<%=Resources.Strings.More%>";
            var lesstext = "<%=Resources.Strings.Less%>";

            $('.more').each(function () {
                var content = $(this).html();

                if (content.length > showChar) {
                    var c = content.substr(0, showChar);
                    var h = content.substr(showChar, content.length - showChar);
                    var html = c + '<span class="moreellipses">' + ellipsestext + '&nbsp;</span><span class="morecontent"><span>' + h + '</span>&nbsp;&nbsp;<a href="" class="morelink">' + moretext + '</a></span>';
                    $(this).html(html);
                }
            });

            $(".morelink").click(function () {
                if ($(this).hasClass("less")) {
                    $(this).removeClass("less");
                    $(this).html(moretext);
                } else {
                    $(this).addClass("less");
                    $(this).html(lesstext);
                }
                $(this).parent().prev().toggle();
                $(this).prev().toggle();
                return false;
            });
        });
    </script>
    <style>
        .more {
            display: block;
            white-space: pre-wrap;
        }

        .morecontent span {
            display: none;
            white-space: pre-wrap;
        }

        .morelink {
            display: block;
        }
    </style>
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnSave" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Save %>"></asp:Button>
            <span class="tooldiv"></span>
            <asp:Button ID="btnConnectorSettings" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, ConnectorSettings %>" />
        </div>
        <div class="body" style="text-align: center">
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <asp:HiddenField ID="hidTabPage" runat="server" ClientIDMode="Static" />
            <asp:HiddenField ID="hidTab" runat="server" ClientIDMode="Static" />
            <div id="tabGeneral" class="tabButton tabButtonActive" runat="server" clientidmode="static"
                width="150px">
                <a href="#void" onclick="pageChange('tabGeneral', 'pageGeneral');return false;">
                    <%=Resources.Strings.General%></a>
            </div>
            <div id="tabDefaults" class="tabButton" runat="server" clientidmode="static" width="150px">
                <a href="#void" onclick="pageChange('tabDefaults', 'pageDefaults');return false;">
                    <%=Resources.Strings.Defaults%></a>
            </div>
            <div id="tabSAML" class="tabButton" runat="server" clientidmode="static" width="150px">
                <a href="#void" onclick="pageChange('tabSAML', 'pageSAML');return false;">
                    <%=Resources.Strings.Saml2%></a>
            </div>
            <div id="tabUserProfileMapping" class="tabButton" runat="server" clientidmode="static" width="150px">
                <a href="#void" onclick="pageChange('tabUserProfileMapping', 'pageUserProfileMapping');return false;">
                    <%=Resources.Strings.UserProfileMapping%></a>
            </div>
            <div id="tabSecurity" class="tabButton" runat="server" clientidmode="static" width="150px">
                <a href="#void" onclick="pageChange('tabSecurity', 'pageSecurity');return false;">
                    <%=Resources.Strings.Security%></a>
            </div>
            <div id="tabRetention" class="tabButton" runat="server" clientidmode="static" width="150px">
                <a href="#void" onclick="pageChange('tabRetention', 'pageRetention');return false;">
                    <%=Resources.Strings.Retention%></a>
            </div>
            <div id="tabSkinSettings" class="tabButton" runat="server" clientidmode="static" width="150px">
                <a href="#void" onclick="pageChange('tabSkinSettings', 'pageSkinSettings');return false;">
                    <%=Intelledox.ViewModel.Core.Resources.Strings.SkinSettings%></a>
            </div>  
            <div id="tabDocuSign" class="tabButton" runat="server" clientidmode="static" width="150px">
                <a href="#void" onclick="pageChange('tabDocuSign', 'pageDocuSign');return false;">
                    <%=Resources.Strings.DocuSign%></a>
            </div>
            <div id="pageGeneral" class="tabPage" runat="server" clientidmode="static">
                <table class="editsectionsettings">
                    <tr id="trManageUrl" runat="server">
                        <td>
                            <asp:Label ID="lblManageUrl" runat="server" Text="<%$Resources:Strings, ManageUrl %>"
                                AssociatedControlID="txtManageUrl" ToolTip="<%$Resources:Strings, ManageUrlToolTip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtManageUrl" runat="server" MaxLength="4000" CssClass="fld" ToolTip="<%$Resources:Strings, ManageUrlToolTip %>"></asp:TextBox>
                        </td>
                    </tr>
                    <tr id="trProduceUrl" runat="server">
                        <td>
                            <asp:Label ID="lblProduceUrl" runat="server" Text="<%$Resources:Strings, ProduceUrl %>"
                                AssociatedControlID="txtProduceUrl" ToolTip="<%$Resources:Strings, ProduceUrlToolTip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtProduceUrl" runat="server" MaxLength="4000" CssClass="fld" ToolTip="<%$Resources:Strings, ProduceUrlToolTip %>"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblApprovals" runat="server" Text="<%$Resources:Strings, RequireApprovals %>"
                                AssociatedControlID="chkApprovals" ToolTip="<%$Resources:Strings, RequireApprovalsToolTip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:CheckBox ID="chkApprovals" runat="server" />
                        </td>
                    </tr>
                    <tr id="trTempDocFolder" runat="server">
                        <td>
                            <asp:Label ID="lblTempDocFolder" runat="server" Text="<%$Resources:Strings, TempDocFolder %>"
                                AssociatedControlID="txtTempDocFolder" ToolTip="<%$Resources:Strings, TempDocFolderToolTip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtTempDocFolder" runat="server" MaxLength="4000" CssClass="fld"
                                ToolTip="<%$Resources:Strings, TempDocFolderToolTip %>"></asp:TextBox>
                            <br />
                            <asp:CustomValidator ID="valTempDocFolder" runat="server" ErrorMessage="<%$Resources:Strings, ValidDirectory %>"
                                Display="Dynamic" OnServerValidate="ValidateTempDocFolder" CssClass="wrn">
                            </asp:CustomValidator>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblFromEmailAddress" runat="server" Text="<%$Resources:Strings, FromEmailAddress %>"
                                AssociatedControlID="txtFromEmailAddress" ToolTip="<%$Resources:Strings, FromEmailAddressToolTip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtFromEmailAddress" runat="server" MaxLength="4000" CssClass="fld"
                                ToolTip="<%$Resources:Strings, FromEmailAddressToolTip %>"></asp:TextBox>
                            <br />
                            <asp:RequiredFieldValidator ID="valFromEmailAddress" runat="Server" ErrorMessage=""
                                Display="Dynamic" ControlToValidate="txtFromEmailAddress" CssClass="wrn"></asp:RequiredFieldValidator>
                        </td>
                    </tr>
                    <tr id="trUsernameText" runat="server">
                        <td>
                            <asp:Label ID="lblUsernameText" runat="server" Text="<%$Resources:Strings, UsernameText %>"
                                AssociatedControlID="txtUsernameText" ToolTip="<%$Resources:Strings, UsernameTextToolTip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtUsernameText" runat="server" MaxLength="4000" CssClass="fld" ToolTip="<%$Resources:Strings, UsernameTextToolTip %>"></asp:TextBox>
                        </td>
                    </tr>
                    <tr id="trSystemName" runat="server">
                        <td>
                           <div style ="display: inline-block"> <asp:Label ID="lblSystemName" runat="server" Text="<%$Resources:Strings, SystemName %>"
                                AssociatedControlID="txtSystemName"></asp:Label></div>
                              <div class ="tooltip">
                            <div class="question-svg"></div>
                            <span class="tooltiptext"><asp:Label ID="lblSystemNameHelp" runat="server" /></span>
                        </div>
                        </td>
                        <td>
                            <asp:TextBox ID="txtSystemName" runat="server" MaxLength="4000" CssClass="fld" type="text"></asp:TextBox>
                        </td>
                    </tr>
                    <tr id="trBrowserTabName">
                    <td>
                        <div style ="display: inline-block"><asp:Label ID="lblBrowserTabName" runat="server" AssociatedControlID="txtBrowserTabName" /></div>
                        <div class ="tooltip">
                            <div class="question-svg"></div>
                            <span class="tooltiptext"><asp:Label ID="lblBrowserTabNameHelp" runat="server" /></span>
                        </div>
                    </td>
                    <td colspan="3">
                        <asp:TextBox ID="txtBrowserTabName" MaxLength="60" CssClass="fld" runat="server" type="text"></asp:TextBox>
                    </td>
                    </tr>
                    <tr id="trGenDocStamp" runat="server">
                        <td>
                           <div style ="display: inline-block"> <asp:Label ID="lblGenDocStamp" runat="server" Text="<%$Resources:Strings, GenDocStamp %>"
                                AssociatedControlID="txtGenDocStamp"></asp:Label></div>
                            <div class ="tooltip">
                            <div class="question-svg"></div>
                            <span class="tooltiptext"><asp:Label ID="lblGenDocStampHelp" runat="server" /></span>
                           </div>
                        </td>
                        <td>
                            <asp:TextBox ID="txtGenDocStamp" runat="server" CssClass="fld" Rows="2" TextMode="MultiLine" Style="width: 400px"></asp:TextBox>
                        </td>
                    </tr>

                    <tr id="trGoogleAnalytics" runat="server">
                        <td>
                            <asp:Label ID="lblGoogleAnalytics" runat="server" Text="<%$Resources:Strings, GoogleAnalytics %>"
                                AssociatedControlID="txtGoogleAnalytics" ToolTip="<%$Resources:Strings, GoogleAnalyticsToolTip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtGoogleAnalytics" runat="server" MaxLength="4000" CssClass="fld" ToolTip="<%$Resources:Strings, GoogleAnalyticsToolTip %>"></asp:TextBox>
                        </td>
                    </tr>
                    <tr id="trEnableAuditing" runat="server">
                        <td>
                            <asp:Label ID="lblEnableAuditing" runat="server" Text="<%$Resources:Strings, EnableAuditing %>"
                                AssociatedControlID="chkEnableAuditing" ToolTip="<%$Resources:Strings, EnableAuditingToolTip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:CheckBox ID="chkEnableAuditing" runat="server" />
                        </td>
                    </tr>
                    <tr id="trLogActions" runat="server">
                        <td>
                            <asp:Label ID="lblLogActions" runat="server" Text="<%$Resources:Strings, LogActions %>"
                                AssociatedControlID="chkLogActions" ToolTip="<%$Resources:Strings, LogActionsTooltip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:CheckBox ID="chkLogActions" runat="server" />
                        </td>
                    </tr>
                    <tr id="trShowOptional" runat="server">
                        <td>
                            <asp:Label ID="lblShowOptional" runat="server" Text="<%$Resources:Strings, ShowOptional %>"
                                AssociatedControlID="chkShowOptional" ToolTip="<%$Resources:Strings, ShowOptionalToolTip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:CheckBox ID="chkShowOptional" runat="server" />
                        </td>
                    </tr>
                    <tr id="trShowProfilePage" runat="server">
                        <td>
                            <asp:Label ID="lblShowProfilePage" runat="server" Text="<%$Resources:Strings, ShowProfilePage %>"
                                AssociatedControlID="chkShowProfilePage" ToolTip="<%$Resources:Strings, ShowProfilePageToolTip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:CheckBox ID="chkShowProfilePage" runat="server" />
                        </td>
                    </tr>
                    <tr id="trTransactionEmail" runat="server">
                        <td>
                            <asp:Label ID="lblTransactionEmail" runat="server" Text="<%$Resources:Strings, TransactionEmail %>"
                                AssociatedControlID="txtTransactionEmail" ToolTip="<%$Resources:Strings, TransactionEmailToolTip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtTransactionEmail" runat="server" MaxLength="4000" CssClass="fld" ToolTip="<%$Resources:Strings, TransactionEmailToolTip %>"></asp:TextBox>
                        </td>
                    </tr>
                    <tr id="trRequireEula" runat="server">
                        <td>
                            <asp:Label ID="lblRequireEula" runat="server" Text="<%$Resources:Strings, RequireEula %>"
                                AssociatedControlID="chkRequireEula" ToolTip="<%$Resources:Strings, RequireEulaToolTip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:CheckBox ID="chkRequireEula" runat="server" />
                        </td>
                    </tr>
                    <tr id="trEula" runat="server">
                        <td>
                            <asp:Label ID="lblEula" runat="server" Text="<%$Resources:Strings, EndUserLicenseAgreementHTML %>"
                                AssociatedControlID="txtEula" ToolTip="<%$Resources:Strings, EndUserLicenseAgreementToolTip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtEula" runat="server" Rows="20" TextMode="MultiLine" CssClass="fld" Style="width: 400px"></asp:TextBox>
                        </td>
                    </tr>
                    <tr id="trResetEula" runat="server">
                        <td>
                            <asp:Label ID="lblResetEula" runat="server" Text="<%$Resources:Strings, ResetEula %>"
                                AssociatedControlID="btnResetEulaAcceptance" ToolTip="<%$Resources:Strings, ResetEulaToolTip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:Button ID="btnResetEulaAcceptance" runat="server" Text="<%$Resources:Strings, UsersMustReaccept %>"></asp:Button>
                        </td>
                    </tr>
                </table>
            </div>
            <div id="pageDefaults" class="tabPage" runat="server" clientidmode="static" style="display: none">
                <table class="editsectionsettings">
                    <tr>
                        <td style="width: 200px">
                            <asp:Label ID="lblDefaultCulture" runat="server" Text="<%$Resources:Strings, DefaultCulture %>"
                                AssociatedControlID="lstDefaultCulture"></asp:Label>
                        </td>
                        <td>
                            <asp:DropDownList ID="lstDefaultCulture" runat="server" EnableViewState="false">
                            </asp:DropDownList>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblDefaultLanguage" runat="server" Text="<%$Resources:Strings, DefaultLanguage %>"
                                AssociatedControlID="lstDefaultLanguage"></asp:Label>
                        </td>
                        <td>
                            <asp:DropDownList ID="lstDefaultLanguage" runat="server" EnableViewState="false">
                            </asp:DropDownList>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblDefaultTimezone" runat="server" Text="<%$Resources:Strings, DefaultTimeZone %>"
                                AssociatedControlID="lstDefaultTimezone"></asp:Label>
                        </td>
                        <td>
                            <asp:DropDownList ID="lstDefaultTimezone" runat="server" EnableViewState="false">
                            </asp:DropDownList>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblPdfDefault" runat="server" Text="<%$Resources:Strings, PdfFormat %>"
                                AssociatedControlID="rdoPdfDefault"></asp:Label>
                        </td>
                        <td>
                            <div>
                                <asp:RadioButton ID="rdoPdfDefault" runat="server" Text="PDF1.5" GroupName="DefaultPDF" />
                            </div>
                            <div>
                                <asp:RadioButton ID="rdoPdfA" runat="server" Text="PDF/A-1b" GroupName="DefaultPDF" />
                            </div>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblEmbedFonts" runat="server" Text="<%$Resources:Strings, DefaultPDFEmbedFonts %>"
                                AssociatedControlID="chkEmbedFonts"></asp:Label>
                        </td>
                        <td>
                            <asp:CheckBox ID="chkEmbedFonts" runat="server" />
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblDocxDefault" runat="server" Text="<%$Resources:Strings, DocxDefaultFormat %>"
                                AssociatedControlID="rdoDocxDefault"></asp:Label>
                        </td>
                        <td>
                            <div>
                                <asp:RadioButton ID="rdoDocxDefault" runat="server" Text="2007" GroupName="DefaultDocx" />
                            </div>
                            <div>
                                <asp:RadioButton ID="rdoDocx2010" runat="server" Text="2010" GroupName="DefaultDocx" />
                            </div>
                        </td>
                    </tr>
                    <tr id="trLogInteractionDefault" runat="server">
                        <td>
                            <asp:Label ID="lblLogInteractionDefault" runat="server" Text="<%$Resources:Strings, DefaultLogInteraction %>"
                                AssociatedControlID="chkLogInteractionDefault"></asp:Label>
                        </td>
                        <td>
                            <div>
                                <asp:CheckBox ID="chkLogInteractionDefault" runat="server" />
                            </div>
                        </td>
                    </tr>
                </table>
            </div>
            <div id="pageSAML" class="tabPage" style="display: none" runat="server" clientidmode="static">
                <table class="editsectionsettings">
                    <tr>
                        <td>
                            <asp:Label ID="lblSaml2" runat="server" Text="<%$Resources:Strings, Saml2%>" AssociatedControlID="chkSaml" />
                        </td>
                        <td>
                            <asp:CheckBox ID="chkSaml" runat="server" />
                        </td>
                    </tr>
                    <asp:Panel ID="pnlSaml" runat="server">
                        <tr>
                            <td>
                                <asp:Label ID="lblCreateUsers" runat="server" Text="<%$Resources:Strings, CreateUsers%>"
                                    AssociatedControlID="chkCreateUsers" ToolTip="<%$Resources:Strings, CreateUsersToolTip %>" />
                            </td>
                            <td>
                                <asp:CheckBox ID="chkCreateUsers" runat="server" />
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="lblIssuer" runat="server" Text="<%$Resources:Strings, Issuer%>" AssociatedControlID="txtIssuer" />
                            </td>
                            <td>
                                <asp:TextBox ID="txtIssuer" runat="server" MaxLength="255" CssClass="fld"></asp:TextBox>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="lblManageEntityId" runat="server" Text="<%$Resources:Strings, ManageEntityId %>"
                                    AssociatedControlID="txtManageEntityId" />
                            </td>
                            <td>
                                <asp:TextBox ID="txtManageEntityId" runat="server" MaxLength="1500" CssClass="fld"></asp:TextBox>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="lblProduceEntityId" runat="server" Text="<%$Resources:Strings, ProduceEntityId %>"
                                    AssociatedControlID="txtProduceEntityId" />
                            </td>
                            <td>
                                <asp:TextBox ID="txtProduceEntityId" runat="server" MaxLength="1500" CssClass="fld"></asp:TextBox>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="lblLoginUrl" runat="server" Text="<%$Resources:Strings, IdentityLoginUrl%>"
                                    AssociatedControlID="txtLoginUrl" />
                            </td>
                            <td>
                                <asp:TextBox ID="txtLoginUrl" runat="server" MaxLength="1500" CssClass="fld"></asp:TextBox>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="lblLogoutUrl" runat="server" Text="<%$Resources:Strings, IdentityLogoutUrl%>"
                                    AssociatedControlID="txtLogoutUrl" />
                            </td>
                            <td>
                                <asp:TextBox ID="txtLogoutUrl" runat="server" MaxLength="1500" CssClass="fld"></asp:TextBox>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <%=Resources.Strings.Certificate%>
                            </td>
                            <td>
                                <asp:RadioButton ID="chkCertificateThumbprint" runat="server" Text="<%$Resources:Strings, CertThumbprint %>"
                                    GroupName="Cert" Checked="true" /><br />
                                <asp:RadioButton ID="chkCertificateUpload" runat="server" Text="<%$Resources:Strings, CertUpload %>"
                                    GroupName="Cert" /><br />
                                <br />
                                <asp:Label ID="lblThumbprint" runat="server" Text="<%$Resources:Strings, Thumbprint %>"
                                    AssociatedControlID="txtCertThumbprint" />
                                <asp:TextBox ID="txtCertThumbprint" runat="server" MaxLength="1500" CssClass="fld"></asp:TextBox>
                                <div id="lblCertDetails" runat="server">
                                    <asp:Literal ID="litCertDetails" runat="server" />
                                </div>
                                <asp:FileUpload ID="filCertificate" runat="server" />
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <%=Resources.Strings.InfinitiCertificate%>
                            </td>
                            <td>
                                <asp:RadioButton ID="chkSpCertificateThumbprint" runat="server" Text="<%$Resources:Strings, CertThumbprint %>"
                                    GroupName="SpCert" Checked="true" /><br />
                                <asp:RadioButton ID="chkSpCertificateUpload" runat="server" Text="<%$Resources:Strings, CertUpload %>"
                                    GroupName="SpCert" /><br />
                                <br />
                                <asp:Label ID="lblSpThumbprint" runat="server" Text="<%$Resources:Strings, Thumbprint %>"
                                    AssociatedControlID="txtSpCertThumbprint" />
                                <asp:TextBox ID="txtSpCertThumbprint" runat="server" MaxLength="1500" CssClass="fld"></asp:TextBox>
                                <div id="lblSpCertDetails" runat="server">
                                    <asp:Literal ID="litSpCertDetails" runat="server" />
                                </div>
                                <asp:FileUpload ID="filSpCertificate" runat="server" />
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="lblSamlLog" runat="server" Text="<%$Resources:Strings, LogMode%>" AssociatedControlID="chkSamlLog" />
                            </td>
                            <td>
                                <asp:CheckBox ID="chkSamlLog" runat="server" />
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="lblLastFailedSamlLogin" runat="server" Text="<%$Resources:Strings, LastFailedSamlLogin%>" AssociatedControlID="lblLastSamlError" />
                            </td>
                            <td>
                                <asp:Label ID="lblLastSamlError" class="more" runat="server" />
                            </td>
                        </tr>
                    </asp:Panel>
                </table>
            </div>
            <div id="pageDocuSign" class="tabPage" style="display: none" runat="server" clientidmode="static">
                <table class="editsectionsettings">
                    <tr>
                        <td>
                            <asp:Label ID="lblProductionEnvironment" runat="server" Text="<%$Resources:Strings, ProductionEnvironment%>" AssociatedControlID="chkProductionEnvironment" />
                        </td>
                        <td>
                            <asp:CheckBox ID="chkProductionEnvironment" runat="server" />
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblAdminAPIUsername" runat="server" Text="<%$Resources:Strings, AdminAPIUsername%>" AssociatedControlID="txtAdminAPIUsername" />
                        </td>
                        <td>
                            <asp:TextBox ID="txtAdminAPIUsername" runat="server" MaxLength="1500" CssClass="fld"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblIntegratorKey" runat="server" Text="<%$Resources:Strings, IntegratorKey%>" AssociatedControlID="txtIntegratorKey" />
                        </td>
                        <td>
                            <asp:TextBox ID="txtIntegratorKey" runat="server" MaxLength="1500" CssClass="fld"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblRSAPrivateKey" runat="server" Text="<%$Resources:Strings, RSAPrivateKey%>" AssociatedControlID="filRSAPrivateKey" />
                        </td>
                        <td>
                            <div id="lblRSAPrivateKeyDetails" runat="server">
                               <asp:Literal ID="litRSAPrivateKeyDetails" runat="server" />
                            </div>
                            <asp:FileUpload ID="filRSAPrivateKey" runat="server" />
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblEmbeddedSigningReturnUrl" runat="server" Text="<%$Resources:Strings, EmbeddedSigningReturnUrl%>" AssociatedControlID="txtEmbeddedSigningReturnUrl" />
                        </td>
                        <td>
                            <asp:TextBox ID="txtEmbeddedSigningReturnUrl" runat="server" MaxLength="1500" CssClass="fld"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblLogMode" runat="server" Text="<%$Resources:Strings, LogMode%>" AssociatedControlID="chkLogMode" />
                        </td>
                        <td>
                            <asp:CheckBox ID="chkLogMode" runat="server" />
                        </td>
                    </tr>
                </table>
            </div>
            <div id="pageUserProfileMapping" class="tabPage" style="display: none" runat="server" clientidmode="static">
                <table class="editsectionsettings">
                    <tr>
                        <td>
                            <asp:Label ID="lblAccountUsername" runat="server" Text="" AssociatedControlID="txtFieldToUsername"></asp:Label></td>
                        <td>
                            <asp:TextBox ID="txtFieldToUsername" runat="server" TabIndex="1" MaxLength="255"></asp:TextBox>
                        </td>
                        <td>
                            <asp:Label ID="lblFieldToGroups" runat="server" Text="<%$Resources:Strings, Groups %>" AssociatedControlID="txtFieldToGroups"></asp:Label>
                        </td>
                        <td colspan="3">
                            <asp:TextBox ID="txtFieldToGroups" runat="server" EnableViewState="false" MaxLength="255"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblFieldToPrefix" runat="server" Text="<%$Resources:Strings, Prefix %>" AssociatedControlID="txtFieldToPrefix"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtFieldToPrefix" runat="server" TabIndex="4" MaxLength="255"></asp:TextBox>
                        <td>
                            <asp:Label ID="lblFieldToJobTitle" runat="server" Text="<%$Resources:Strings, JobTitle %>" AssociatedControlID="txtFieldToJobTitle"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtFieldToJobTitle" runat="server" TabIndex="8" MaxLength="255"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblFieldToFirstName" runat="server" Text="<%$Resources:Strings, FirstName %>" AssociatedControlID="txtFieldToFirstName"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtFieldToFirstName" runat="server" TabIndex="5" MaxLength="255"></asp:TextBox>
                        </td>
                        <td>
                            <asp:Label ID="lblFieldToOrganisation" runat="server" Text="<%$Resources:Strings, Organisation %>" AssociatedControlID="txtFieldToOrganisation"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtFieldToOrganisation" runat="server" TabIndex="9" MaxLength="255"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblFieldToLastName" runat="server" Text="<%$Resources:Strings, LastName %>" AssociatedControlID="txtFieldToLastName"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtFieldToLastName" runat="server" TabIndex="6" MaxLength="255"></asp:TextBox>
                        </td>
                        <td>
                            <asp:Label ID="lblFieldToPhoneNumber" runat="server" Text="<%$Resources:Strings, PhoneNumber %>" AssociatedControlID="txtFieldToPhoneNumber"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtFieldToPhoneNumber" runat="server" TabIndex="10" MaxLength="255"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblFullName" runat="server" Text="<%$Resources:Strings, FullName %>" AssociatedControlID="txtFieldToFullName"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtFieldToFullName" runat="server" TabIndex="11" MaxLength="255"></asp:TextBox>
                        </td>
                        <td>
                            <asp:Label ID="lblFieldToFaxNumber" runat="server" Text="<%$Resources:Strings, FaxNumber %>" AssociatedControlID="txtFieldToFaxNumber"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtFieldToFaxNumber" runat="server" TabIndex="11" MaxLength="255"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td colspan="2"></td>
                        <td>
                            <asp:Label ID="lblFieldToEmail" runat="server" Text="<%$Resources:Strings, Email %>" AssociatedControlID="txtFieldToEmail"></asp:Label>
                        </td>

                        <td>
                            <asp:TextBox ID="txtFieldToEmail" runat="server" TabIndex="7" MaxLength="255"></asp:TextBox>

                        </td>
                    </tr>

                    <tr>
                        <th colspan="2">
                            <asp:Literal runat="server" Text="<%$Resources:Strings, StreetAddress %>" /></th>
                        <th colspan="2">
                            <asp:Literal runat="server" Text="<%$Resources:Strings, PostalAddress %>" /></th>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblFieldToSAddress1" runat="server" Text="<%$Resources:Strings, AddressLine1 %>" AssociatedControlID="txtFieldToSAddress1"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtFieldToSAddress1" runat="server" TabIndex="12" MaxLength="255"></asp:TextBox>
                        </td>
                        <td>
                            <asp:Label ID="lblFieldToPAddress1" runat="server" Text="<%$Resources:Strings, AddressLine1 %>" AssociatedControlID="txtFieldToPAddress1"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtFieldToPAddress1" runat="server" TabIndex="18" MaxLength="255"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblFieldToSAddress2" runat="server" Text="<%$Resources:Strings, AddressLine2 %>" AssociatedControlID="txtFieldToSAddress2"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtFieldToSAddress2" runat="server" TabIndex="13" MaxLength="255"></asp:TextBox>
                        </td>
                        <td>
                            <asp:Label ID="lblFieldToPAddress2" runat="server" Text="<%$Resources:Strings, AddressLine2 %>" AssociatedControlID="txtFieldToPAddress2"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtFieldToPAddress2" runat="server" TabIndex="19" MaxLength="255"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblFieldToSSuburb" runat="server" Text="<%$Resources:Strings, SuburbTownCity %>" AssociatedControlID="txtFieldToSSuburb"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtFieldToSSuburb" runat="server" TabIndex="14" MaxLength="255"></asp:TextBox>
                        </td>
                        <td>
                            <asp:Label ID="lblFieldToPSuburb" runat="server" Text="<%$Resources:Strings, SuburbTownCity %>" AssociatedControlID="txtFieldToPSuburb"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtFieldToPSuburb" runat="server" TabIndex="20" MaxLength="255"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblFieldToSState" runat="server" Text="<%$Resources:Strings, StateProvinceRegion %>" AssociatedControlID="txtFieldToSState"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtFieldToSState" runat="server" TabIndex="15" MaxLength="255"></asp:TextBox>
                        </td>
                        <td>
                            <asp:Label ID="lblFieldToPState" runat="server" Text="<%$Resources:Strings, StateProvinceRegion %>" AssociatedControlID="txtFieldToPState"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtFieldToPState" runat="server" TabIndex="21" MaxLength="255"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblFieldToSPostal" runat="server" Text="<%$Resources:Strings, PostalZipCode %>" AssociatedControlID="txtFieldToSPostal"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtFieldToSPostal" runat="server" TabIndex="16" MaxLength="255"></asp:TextBox>
                        </td>
                        <td>
                            <asp:Label ID="lblFieldToPPostal" runat="server" Text="<%$Resources:Strings, PostalZipCode %>" AssociatedControlID="txtFieldToPPostal"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtFieldToPPostal" runat="server" TabIndex="22" MaxLength="255"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblFieldToSCountry" runat="server" Text="<%$Resources:Strings, Country %>" AssociatedControlID="txtFieldToSCountry"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtFieldToSCountry" runat="server" TabIndex="17" MaxLength="255"></asp:TextBox>
                        </td>
                        <td>
                            <asp:Label ID="lblFieldToPCountry" runat="server" Text="<%$Resources:Strings, Country %>" AssociatedControlID="txtFieldToPCountry"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtFieldToPCountry" runat="server" TabIndex="23" MaxLength="255"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <th colspan="4">
                            <asp:Literal ID="litRegionalOptions" runat="server" Text="<%$Resources:Strings, RegionalOptions %>" /></th>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblFieldToCulture" runat="server" Text="<%$Resources:Strings, Culture %>" AssociatedControlID="txtFieldToCulture"></asp:Label>
                        </td>
                        <td colspan="3">
                            <asp:TextBox ID="txtFieldToCulture" runat="server" MaxLength="255"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblFieldToLanguage" runat="server" Text="<%$Resources:Strings, Language %>" AssociatedControlID="txtFieldToLanguage"></asp:Label>
                        </td>
                        <td colspan="3">
                            <asp:TextBox ID="txtFieldToLanguage" runat="server" MaxLength="255"></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblFieldToTimezome" runat="server" Text="<%$Resources:Strings, Timezone %>" AssociatedControlID="txtFieldToTimezone"></asp:Label>
                        </td>
                        <td colspan="3">
                            <asp:TextBox ID="txtFieldToTimeZone" runat="server" MaxLength="255"></asp:TextBox>
                        </td>
                    </tr>
                    <asp:Repeater ID="rptUserCustFields" runat="server">
                        <HeaderTemplate>
                            <tr>
                                <th colspan="4">
                                    <asp:Literal ID="litUserCusomFields" runat="server" Text="<%$Resources:Strings, CustomFields %>" />
                                </th>
                            </tr>
                        </HeaderTemplate>
                        <ItemTemplate>
                            <tr>
                                <td>
                                    <asp:Label runat="server" ID="lblName" Text='<%# Microsoft.Security.Application.Encoder.HtmlEncode(DataBinder.Eval(Container.DataItem, "Title")) %>' AssociatedControlID="txtCustUserFieldVal"></asp:Label>
                                </td>
                                <td>
                                    <asp:TextBox ID="txtCustUserFieldVal" runat="server" MaxLength="255"></asp:TextBox>
                                </td>
                                <td colspan="2" />
                            </tr>
                        </ItemTemplate>
                    </asp:Repeater>
                </table>
            </div>
            <div id="pageSecurity" class="tabPage" style="display: none" runat="server" clientidmode="static">
                <table class="editsectionsettings">
                    <tr>
                        <th><%=Resources.Strings.Setting%></th>
                        <th><%=Resources.Strings.Enabled%></th>
                        <th><%=Resources.Strings.Description%></th>
                        <th><%=Resources.Strings.Value%></th>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblMinPasswordLength" runat="server" Text="<%$Resources:Strings, SecurityPasswordLength%>"
                                AssociatedControlID="chkMinPasswordLength" ToolTip="<%$Resources:Strings, SecurityPasswordLength%>"></asp:Label>
                        </td>
                        <td style="width: 10%">
                            <asp:CheckBox ID="chkMinPasswordLength" runat="server" Text="" />
                        </td>
                        <td>
                            <asp:Label ID="lblMinPasswordLengthDescription" runat="server" Text="<%$Resources:Strings, SecurityPasswordLengthDescription%>"
                                AssociatedControlID="txtMinPasswordLength" ToolTip="<%$Resources:Strings, SecurityPasswordLengthDescription%>"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtMinPasswordLength" runat="server" MaxLength="3" CssClass="fld" ToolTip="<%$Resources:Strings, SecurityPasswordLength%>"></asp:TextBox>
                            <asp:CustomValidator ID="ValMinimumPasswordLength" runat="server" ErrorMessage="<%$Resources:Strings, NumericType %>"
                                Display="Dynamic" ClientValidationFunction="validateNumeric" ControlToValidate="txtMinPasswordLength" CssClass="wrn">
                            </asp:CustomValidator>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblInvalidPasswordAttempts" runat="server" Text="<%$Resources:Strings, SecurityInvalidAttemptsBeforeLockOut%>"
                                AssociatedControlID="chkInvalidPasswordAttempts" ToolTip="<%$Resources:Strings, SecurityInvalidAttemptsBeforeLockOut%>"></asp:Label>
                        </td>
                        <td style="width: 10%">
                            <asp:CheckBox ID="chkInvalidPasswordAttempts" runat="server" Text="" />
                        </td>
                        <td>
                            <asp:Label ID="lblInvalidPasswordAttemptsDescription" runat="server" Text="<%$Resources:Strings, SecurityInvalidAttemptsBeforeLockOutDescription%>"
                                AssociatedControlID="txtInvalidPasswordAttempts" ToolTip="<%$Resources:Strings, SecurityInvalidAttemptsBeforeLockOutDescription%>"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtInvalidPasswordAttempts" runat="server" MaxLength="3" CssClass="fld" ToolTip="<%$Resources:Strings, SecurityInvalidAttemptsBeforeLockOutDescription%>"></asp:TextBox>
                            <asp:CustomValidator ID="ValInvalidPasswordAttempts" runat="server" ErrorMessage="<%$Resources:Strings, NumericType %>"
                                Display="Dynamic" ClientValidationFunction="validateNumeric" ControlToValidate="txtInvalidPasswordAttempts" CssClass="wrn">
                            </asp:CustomValidator>
                        </td>
                    </tr>

                    <tr>
                        <td>
                            <asp:Label ID="lblPasswordHistoryCount" runat="server" Text="<%$Resources:Strings, SecurityNumberOfOldPasswordsToKeep%>"
                                AssociatedControlID="chkPasswordHistoryCount" ToolTip="<%$Resources:Strings, SecurityNumberOfOldPasswordsToKeep%>"></asp:Label>
                        </td>
                        <td style="width: 10%">
                            <asp:CheckBox ID="chkPasswordHistoryCount" runat="server" Text="" />
                        </td>
                        <td>
                            <asp:Label ID="lblPasswordHistoryCountDescription" runat="server" Text="<%$Resources:Strings, SecurityNumberOfOldPasswordsToKeepDescription%>"
                                AssociatedControlID="txtPasswordHistoryCount" ToolTip="<%$Resources:Strings, SecurityNumberOfOldPasswordsToKeepDescription%>"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtPasswordHistoryCount" runat="server" MaxLength="3" CssClass="fld" ToolTip="<%$Resources:Strings, SecurityNumberOfOldPasswordsToKeep%>"></asp:TextBox>
                            <asp:CustomValidator ID="ValPasswordHistoryCount" runat="server" ErrorMessage="<%$Resources:Strings, NumericType %>"
                                Display="Dynamic" ClientValidationFunction="validateNumeric" ControlToValidate="txtPasswordHistoryCount" CssClass="wrn">
                            </asp:CustomValidator>
                        </td>
                    </tr>

                    <tr>
                        <td>
                            <asp:Label ID="lblMaximumPasswordAge" runat="server" Text="<%$Resources:Strings, SecurityMaximumPasswordAge%>"
                                AssociatedControlID="chkMaximumPasswordAge" ToolTip="<%$Resources:Strings, SecurityMaximumPasswordAge%>"></asp:Label>
                        </td>
                        <td style="width: 10%">
                            <asp:CheckBox ID="chkMaximumPasswordAge" runat="server" Text="" />
                        </td>
                        <td>
                            <asp:Label ID="lblMaximumPasswordAgeDescription" runat="server" Text="<%$Resources:Strings, SecurityMaximumPasswordAgeDescription%>"
                                AssociatedControlID="txtMaximumPasswordAge" ToolTip="<%$Resources:Strings, SecurityMaximumPasswordAgeDescription%>"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtMaximumPasswordAge" runat="server" MaxLength="3" CssClass="fld" ToolTip="<%$Resources:Strings, SecurityMaximumPasswordAge%>"></asp:TextBox>
                            <asp:CustomValidator ID="ValMaximumPasswordAge" runat="server" ErrorMessage="<%$Resources:Strings, NumericType %>"
                                Display="Dynamic" ClientValidationFunction="validateNumeric" ControlToValidate="txtMaximumPasswordAge" CssClass="wrn">
                            </asp:CustomValidator>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblComplexPasswords" runat="server" Text="<%$Resources:Strings, SecurityComplexPasswords%>"
                                AssociatedControlID="chkComplexPasswords" ToolTip="<%$Resources:Strings, SecurityComplexPasswords%>"></asp:Label>
                        </td>
                        <td style="width: 10%">
                            <asp:CheckBox ID="chkComplexPasswords" runat="server" Text="" />
                        </td>
                        <td colspan="2">
                            <asp:Label ID="lblComplexPasswordsDescription" runat="server" Text=""
                                AssociatedControlID="" ToolTip=""></asp:Label>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblDisallowCommonPwds" runat="server" Text="<%$Resources:Strings, SecurityDisallowCommonPwds%>"
                                AssociatedControlID="chkDisallowCommonPwds" ToolTip="<%$Resources:Strings, SecurityDisallowCommonPwds%>"></asp:Label>
                        </td>
                        <td style="width: 10%">
                            <asp:CheckBox ID="chkDisallowCommonPwds" runat="server" Text="" />
                        </td>
                        <td colspan="2">
                            <asp:Label ID="lblDisallowCommonPwdsDescription" runat="server" Text="<%$Resources:Strings, SecurityDisallowCommonPwdsDescription%>"
                                AssociatedControlID="" ToolTip="<%$Resources:Strings, SecurityDisallowCommonPwdsDescription%>"></asp:Label>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblExcelEscape" runat="server" Text="<%$Resources:Strings, SecurityEscapeExcelFormulas%>"
                                AssociatedControlID="chkExcelEscape" ToolTip="<%$Resources:Strings, SecurityEscapeExcelFormulas%>"></asp:Label>
                        </td>
                        <td style="width: 10%">
                            <asp:CheckBox ID="chkExcelEscape" runat="server" Text="" />
                        </td>
                        <td colspan="2">
                            <asp:Label ID="lblSecurityEscapeExcelFormulas" runat="server" Text="<%$Resources:Strings, SecurityEscapeExcelFormulasDescription%>"
                                AssociatedControlID="" ToolTip="<%$Resources:Strings, SecurityEscapeExcelFormulasDescription%>"></asp:Label>
                        </td>
                    </tr>
                    <tr id="trEncryptData" runat="server">
                        <td>
                            <asp:Label ID="lblEncryptData" runat="server" Text="<%$Resources:Strings, EncryptData%>"
                                AssociatedControlID="chkEncryptData" ToolTip="<%$Resources:Strings, EncryptData%>"></asp:Label>
                        </td>
                        <td style="width: 10%">
                            <asp:CheckBox ID="chkEncryptData" runat="server" Text="" />
                        </td>
                        <td colspan="2">
                            <asp:Label ID="lblEncryptDescription" runat="server" Text="<%$Resources:Strings, EncryptDataDescription%>"
                                ToolTip="<%$Resources:Strings, EncryptDataDescription%>"></asp:Label>
                        </td>
                    </tr>
                    <tr id="trTimeBetweenLogonAttempts" runat="server">
                        <td colspan="3">
                            <asp:Label ID="lblTimeBetweenLogonAttemptsDescription" runat="server" Text="<%$Resources:Strings, TimeBetweenLogonAttemptsDescription%>"
                                AssociatedControlID="txtTimeBetweenLogonAttempts" ToolTip="<%$Resources:Strings, TimeBetweenLogonAttemptsDescription%>"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtTimeBetweenLogonAttempts" runat="server" MaxLength="3" CssClass="fld" ToolTip="<%$Resources:Strings, TimeBetweenLogonAttempts%>"></asp:TextBox>
                            <asp:CustomValidator ID="valTimeBetweenLogonAttempts" runat="server" ErrorMessage="<%$Resources:Strings, NumericType %>"
                                Display="Dynamic" ClientValidationFunction="validateNumericGreaterThanZero" ControlToValidate="txtTimeBetweenLogonAttempts" CssClass="wrn" ValidateEmptyText="true">
                            </asp:CustomValidator>
                        </td>
                    </tr>

                    <tr>
                        <th colspan="4">
                            <asp:Literal runat="server" Text="<%$Resources:Strings, iOSPushSettings %>" /></th>
                    </tr>
                    <tr>
                        <td>
                            <%=Resources.Strings.Certificate%>
                        </td>
                        <td colspan="3">
                            <div id="lblAppleCertPrintDetails" runat="server">
                                <asp:Literal ID="litAppleCertPrintDetails" runat="server" />
                            </div>
                            <asp:FileUpload ID="filAppleUpload" runat="server" />
                        </td>
                    </tr>

                    <tr>
                        <td>
                            <%=Resources.Strings.Password %>
                        </td>
                        <td colspan="3">
                            <asp:TextBox ID="txtAppleCertPassword" runat="server" TextMode="Password" />
                        </td>
                    </tr>

                    <tr>
                        <th colspan="4">
                            <asp:Literal runat="server" Text="<%$Resources:Strings, AndroidSettings %>" /></th>
                    </tr>
                    <tr>
                        <td>
                            <%=Resources.Strings.AndroidPushNotificationsServerKey %>
                        </td>
                        <td colspan="3">
                            <asp:TextBox ID="txtAndroidKey" runat="server" TextMode="Password" />
                        </td>
                    </tr>

                </table>
            </div>
            <div id="pageRetention" class="tabPage" style="display: none" runat="server" clientidmode="static">
                <table class="editsectionsettings">
                    <tr>
                        <td>
                            <asp:Label ID="lblMaxVersions" runat="server" Text="<%$Resources:Strings, MaxVersions %>"
                                AssociatedControlID="txtMaxVersions" ToolTip="<%$Resources:Strings, MaxVersionsToolTip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtMaxVersions" runat="server" MaxLength="10" CssClass="fld" ToolTip="<%$Resources:Strings, MaxVersionsToolTip %>"></asp:TextBox>
                            <br />
                            <asp:CustomValidator ID="valMaxVersions" runat="server" ErrorMessage="<%$Resources:Strings, NumericType %>"
                                Display="Dynamic" ClientValidationFunction="validateNumeric" CssClass="wrn" ControlToValidate="txtMaxVersions" ValidateEmptyText="true">
                            </asp:CustomValidator>
                        </td>
                    </tr>
                    <tr id="trCleanupHours" runat="server">
                        <td>
                            <asp:Label ID="lblCleanupHours" runat="server" Text="<%$Resources:Strings, CleanupHours %>"
                                AssociatedControlID="txtCleanupHours" ToolTip="<%$Resources:Strings, CleanupHoursToolTip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtCleanupHours" runat="server" MaxLength="10" CssClass="fld" ToolTip="<%$Resources:Strings, CleanupHoursToolTip %>"></asp:TextBox>
                            <br />
                            <asp:CustomValidator ID="valCleanupHours" runat="server" ErrorMessage="<%$Resources:Strings, NumericType %>"
                                Display="Dynamic" ClientValidationFunction="validateNumeric" CssClass="wrn" ControlToValidate="txtCleanupHours" ValidateEmptyText="true">
                            </asp:CustomValidator>
                        </td>
                    </tr>
                    <tr id="trDownloadableDocNum" runat="server">
                        <td>
                            <asp:Label ID="lblDownloadableDocNum" runat="server" Text="<%$Resources:Strings, NumberOfDownloadableDocuments %>"
                                AssociatedControlID="txtDownloadableDocNum" ToolTip="<%$Resources:Strings, DownloadableDocNumToolTip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtDownloadableDocNum" runat="server" MaxLength="10" CssClass="fld"
                                ToolTip="<%$Resources:Strings, DownloadableDocNumToolTip %>"></asp:TextBox>
                            <br />
                            <asp:CustomValidator ID="valDownloadableDocNum" runat="server" ErrorMessage="<%$Resources:Strings, NumericType %>"
                                Display="Dynamic" ClientValidationFunction="validateNumeric" CssClass="wrn" ControlToValidate="txtDownloadableDocNum" ValidateEmptyText="true">
                            </asp:CustomValidator>
                        </td>
                    </tr>
                    <tr id="trGenerationDays" runat="server">
                        <td>
                            <asp:Label ID="lblGenerationDays" runat="server" Text="<%$Resources:Strings, RetainGenerationDays %>"
                                AssociatedControlID="txtGenerationDays" ToolTip="<%$Resources:Strings, RetainGenerationDaysToolTip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtGenerationDays" runat="server" MaxLength="10" CssClass="fld"
                                ToolTip="<%$Resources:Strings, RetainGenerationDaysToolTip %>"></asp:TextBox>
                            <br />
                            <asp:CustomValidator ID="valRetainGenerationDaysNum" runat="server"
                                Display="Dynamic" ClientValidationFunction="validateGenerationDays" CssClass="wrn" ControlToValidate="txtGenerationDays" ValidateEmptyText="true">
                            </asp:CustomValidator>
                        </td>
                    </tr>
                    <tr id="trAuditDays" runat="server">
                        <td>
                            <asp:Label ID="lblAuditDays" runat="server" Text="<%$Resources:Strings, RetainAuditDays %>"
                                AssociatedControlID="txtAuditDays" ToolTip="<%$Resources:Strings, RetainAuditDaysToolTip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtAuditDays" runat="server" MaxLength="10" CssClass="fld"
                                ToolTip="<%$Resources:Strings, RetainAuditDaysToolTip %>"></asp:TextBox>
                            <br />
                            <asp:CustomValidator ID="valRetainAuditDaysNum" runat="server" ErrorMessage="<%$Resources:Strings, NumericType %>"
                                Display="Dynamic" ClientValidationFunction="validateNumeric" CssClass="wrn" ControlToValidate="txtAuditDays" ValidateEmptyText="true">
                            </asp:CustomValidator>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblKeepWorkflowHistory" runat="server" Text="<%$Resources:Strings, KeepWorkflowHistory %>"
                                AssociatedControlID="chkKeepWorkflowHistory" ToolTip="<%$Resources:Strings, KeepWorkflowHistoryToolTip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:CheckBox ID="chkKeepWorkflowHistory" runat="server" />
                        </td>
                    </tr>
                    <tr id="trStoreLocationData" runat="server" visible="False">
                        <td>
                            <div style="display:inline-block"><asp:Label ID="lbStoreLocationData" runat="server" Text="<%$Resources:Strings, StoreLocationData %>"
                                                                         AssociatedControlID="chkStoreLocationData"></asp:Label></div>
                            <div class ="tooltip">
                                <div class="question-svg"></div>
                                <span class="tooltiptext"><asp:Label ID="lblChkStoreLocationDataHelp" runat="server" /></span>
                            </div>
                        </td>
                        <td>
                            <asp:CheckBox ID="chkStoreLocationData" runat="server" />
                        </td>
                    </tr>
                    <tr id="trWorkflowDays" runat="server">
                        <td>
                            <asp:Label ID="lblWorkflowDays" runat="server" Text="<%$Resources:Strings, RetainWorkflowDays %>"
                                AssociatedControlID="txtAuditDays" ToolTip="<%$Resources:Strings, RetainWorkflowDaysToolTip %>"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtWorkflowDays" runat="server" MaxLength="10" CssClass="fld"
                                ToolTip="<%$Resources:Strings, RetainWorkflowDaysToolTip %>"></asp:TextBox>
                            <br />
                            <asp:CustomValidator ID="valRetainWorkflowDaysNum" runat="server" ErrorMessage="<%$Resources:Strings, NumericType %>"
                                Display="Dynamic" ClientValidationFunction="validateNumeric" CssClass="wrn" ControlToValidate="txtAuditDays" ValidateEmptyText="true">
                            </asp:CustomValidator>
                        </td>
                    </tr>
                </table>
            </div>
            <div id="pageSkinSettings" class="tabPage" style="display: none" runat="server" clientidmode="static">
                <control1:SkinSettings ID="businessUnitSkin" runat="server" />
            </div>
        </div>
    </div>
</asp:Content>
