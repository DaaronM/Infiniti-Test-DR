<%@ Page Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="TenantEdit.aspx.vb" Inherits="ManagementPortal.TenantEdit" %>
<asp:Content ID="Javascript1" ContentPlaceHolderID="Javascript" runat="server">
    <script src="Scripts/jquery-2.1.0.min.js" type="text/javascript"></script>
    <script src="Scripts/TabPages.js?v=8.1" type="text/javascript"></script>
</asp:Content>

<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnSave" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Save %>" />
            <asp:Button ID="btnLicensing" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Licensing %>" CausesValidation="false" />
            <span class="tooldiv"></span>
            <asp:Button ID="btnImport" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, ImportTemplates %>" CausesValidation="false" />
            <span class="tooldiv"></span>
            <asp:Button ID="btnDeactivate" runat="server" CssClass="toolbtn" Text="" CausesValidation="false" />
            <span class="tooldiv"></span>
            <asp:Button ID="btnAdmin" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, NewTenantAdmin %>" CausesValidation="false" />
            <span class="tooldiv"></span>
            <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Back %>" CausesValidation="false" />
        </div>
        <div class="body">
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <asp:HiddenField ID="hidTabPage" runat="server" ClientIDMode="Static" />
            <asp:HiddenField ID="hidTab" runat="server" ClientIDMode="Static" />
            <div id="tabGeneral" class="tabButton tabButtonActive" runat="server" clientidmode="static"
                width="150px">
                <a href="#void" onclick="pageChange('tabGeneral', 'pageGeneral');return false;"><%=Resources.Strings.General %></a>
            </div>
            <div id="tabSkinSettings" class="tabButton" runat="server" clientidmode="static" width="150px">
                <a href="#void" onclick="pageChange('tabSkinSettings', 'pageSkinSettings');return false;"><%=SkinLinkText%></a>
            </div>
            <div id="pageGeneral" class="tabPage" runat="server" clientidmode="static">
                <table style="width: 100%;" class="editsection" role="presentation">
                    <tr>
                        <td style="width: 15%;">*<asp:Label ID="lblTenantName" runat="server" Text="<%$Resources:Strings, TenantName %>"
                            AssociatedControlID="txtTenantName"></asp:Label>
                        </td>
                        <td style="width: 10%;">
                            <asp:TextBox ID="txtTenantName" runat="server" MaxLength="200"></asp:TextBox>
                            <asp:RequiredFieldValidator ID="rfvTenantName" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtTenantName" CssClass="wrn"></asp:RequiredFieldValidator>
                        </td>
                        <td style="width: 75%;">&nbsp;&nbsp;     
                        </td>
                    </tr>
                    <tr id="trBrowserTabName">
                        <td style="width: 15%;">
                            <div style ="display: inline-block"><asp:Label ID="lblBrowserTabName" runat="server" AssociatedControlID="txtBrowserTabName" /></div>
                            <div class ="tooltip">
                                <div class="question-svg"></div>
                                <span class="tooltiptext"><asp:Label ID="lblBrowserTabNameHelp" runat="server" /></span>
                            </div>
                        </td>
                        <td style="width: 10%;">
                            <asp:TextBox ID="txtBrowserTabName" MaxLength="60" runat="server"></asp:TextBox>
                        </td>
                         <td style="width: 75%;">&nbsp;&nbsp;     
                        </td>
                    </tr>
                    <tr>
                        <td style="width: 15%;">
                            <div style="display: inline-block"><asp:Label ID="lblCustomProduceUrl" runat="server" AssociatedControlID="txtCustomProduceUrl" /></div>
                        </td>
                        <td style="width: 10%;">
                            <asp:TextBox ID="txtCustomProduceUrl" runat="server"></asp:TextBox>
                        </td>
                         <td style="width: 75%;">&nbsp;&nbsp;     
                        </td>
                    </tr>
                    <tr>
                        <td style="width: 15%;">
                            <div style="display: inline-block"><asp:Label ID="lblCustomManageUrl" runat="server" AssociatedControlID="txtCustomManageUrl" /></div>
                        </td>
                        <td style="width: 10%;">
                            <asp:TextBox ID="txtCustomManageUrl" runat="server"></asp:TextBox>
                        </td>
                         <td style="width: 75%;">&nbsp;&nbsp;     
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblTenantType" runat="server" Text="<%$Resources:Strings, TenantType %>" AssociatedControlID="lstTenantType"></asp:Label>
                        </td>
                        <td colspan="2">
                            <asp:DropDownList ID="lstTenantType" runat="server">
                            </asp:DropDownList>
                        </td>
                    </tr>

                    <tr>
                        <th colspan="3">
                            <asp:Literal ID="Literal1" runat="server" Text="<%$Resources:Strings, AdminUserDetails %>" /></th>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblUsername" runat="server" Text="<%$Resources:Strings, Username %>"
                                AssociatedControlID="lstUsername"></asp:Label>
                        </td>
                        <td>
                            <asp:DropDownList ID="lstUsername" runat="server" AutoPostBack="true">
                            </asp:DropDownList>
                        </td>
                        <td>&nbsp;&nbsp;<asp:Button ID="btnResetPwd" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, ResetPwd %>" Enabled="false" />&nbsp;&nbsp;
                        <asp:Button ID="btnDisableUser" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, DisableUser %>" Enabled="false" />
                        </td>
                    </tr>
                    <tr>
                        <td colspan="3">&nbsp;</td>
                    </tr>
                    <tr runat="server" id="trPwd">
                        <td>*<asp:Label ID="lblPassword" runat="server" Text="<%$Resources:Strings, Password %>"
                            AssociatedControlID="txtPassword"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtPassword" runat="server" MaxLength="50" TextMode="Password"></asp:TextBox>
                        </td>
                        <td>&nbsp;</td>
                    </tr>
                    <tr runat="server" id="trConfirmPwd">
                        <td>
                            <asp:Label ID="lblConfirmPassword" runat="server" Text="<%$Resources:Strings, ConfirmPassword %>"
                                AssociatedControlID="txtConfirmPassword"></asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtConfirmPassword" runat="server" MaxLength="50" TextMode="Password"></asp:TextBox>
                        </td>
                        <td>
                            <asp:Button ID="btnReset" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Reset %>" />
                        </td>
                    </tr>
                    <tr id="trUserContactDetails" runat="server">
                        <td colspan="3">
                            <table style="width: 100%;" class="editsection" role="presentation">
                                <tr>
                                    <th colspan="2">
                                        <asp:Literal ID="Literal2" runat="server" Text="<%$Resources:Strings, UserContactDetails %>" /></th>
                                </tr>
                                <tr>
                                    <td style="width: 11%;">
                                        <b>
                                            <asp:Label ID="lblFirstName" runat="server" Text="<%$Resources:Strings, FirstName %>"></asp:Label></b>:
                                    </td>
                                    <td style="width: 89%;">
                                        <asp:Label ID="txtFirstName" runat="server" Text=""></asp:Label>
                                    </td>
                                </tr>
                                <tr>
                                    <td>
                                        <b>
                                            <asp:Label ID="lblLastName" runat="server" Text="<%$Resources:Strings, LastName %>"></asp:Label></b>:
                                    </td>
                                    <td>
                                        <asp:Label ID="txtLastName" runat="server" Text=""></asp:Label>
                                    </td>
                                </tr>
                                <tr>
                                    <td>
                                        <b>
                                            <asp:Label ID="lblPhone" runat="server" Text="<%$Resources:Strings, PhoneNumber %>"></asp:Label></b>:
                                    </td>
                                    <td>
                                        <asp:Label ID="txtPhone" runat="server" Text=""></asp:Label>
                                    </td>
                                </tr>
                                <tr>
                                    <td>
                                        <b>
                                            <asp:Label ID="lblEmail" runat="server" Text="<%$Resources:Strings, Email %>"></asp:Label></b>:
                                    </td>
                                    <td>
                                        <asp:Label ID="txtEmail" runat="server" Text=""></asp:Label>
                                    </td>
                                </tr>
                                <tr>
                                    <td>
                                        <b>
                                            <asp:Label ID="lblCountry" runat="server" Text="<%$Resources:Strings, Country %>"></asp:Label></b>:
                                    </td>
                                    <td>
                                        <asp:Label ID="txtCountry" runat="server" Text=""></asp:Label>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>
            </div>
            <div id="pageSkinSettings" class="tabPage" style="display: none" runat="server" clientidmode="static">
                <asp:PlaceHolder ID="businessUnitSkinPlaceholder" runat="server" />
            </div>
        </div>
    </div>
</asp:Content>

