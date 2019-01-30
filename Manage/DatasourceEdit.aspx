<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.DatasourceEdit"
    CodeBehind="DatasourceEdit.aspx.vb" %>

<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <script src="Scripts/jquery-3.1.1.min.js" type="text/javascript"></script>
    <script src="Scripts/jquery-ui-1.12.1.custom.min.js" type="text/javascript"></script>
    <script type="text/javascript">
        function checkFields() {
            var ctl = document.getElementById('<%=optConnectWithProvided.ClientId %>');

            if (ctl.checked) {
                document.getElementById('<%=txtUserName.ClientId %>').disabled = false;
                document.getElementById('<%=txtPassword.ClientId %>').disabled = false;
            } else {
                document.getElementById('<%=txtUserName.ClientId %>').value = '';
                document.getElementById('<%=txtPassword.ClientId %>').value = '';
                document.getElementById('<%=txtUserName.ClientId %>').disabled = true;
                document.getElementById('<%=txtPassword.ClientId %>').disabled = true;
            }
        }

        function showSchemaDialog() {
            document.getElementById('<%=filSchema.ClientID%>').click();
        }

        function showDefaultDataDialog() {
            document.getElementById('<%=filDefaultData.ClientID%>').click();
        }

        function newSchemaUpload(file) {
            document.getElementById('<%=hdnRemoveSchema.ClientID%>').value = 'false';
            document.getElementById('<%=lblSchemaFileName.ClientID%>').innerText = file.files[0].name;
            var downloadLink = document.getElementById('<%=hypSchemaDownload.ClientID%>');
            if (downloadLink != null) {
                downloadLink.style.display = 'none';
            }
            var removeLink = document.getElementById('<%=lnkSchemaRemove.ClientID%>');
            if (removeLink != null) {
                removeLink.style.display = 'none';
            }
        }

        function newDefaultDataUpload(file) {
            document.getElementById('<%=hdnRemoveDefaultData.ClientID%>').value = 'false';
            document.getElementById('<%=lblDefaultDataFileName.ClientID%>').innerText = file.files[0].name;
            var downloadLink = document.getElementById('<%=hypDefaultDataDownload.ClientID%>');
            if (downloadLink != null) {
                downloadLink.style.display = 'none';
            }
            var removeLink = document.getElementById('<%=lnkDefaultDataRemove.ClientID%>');
            if (removeLink != null) {
                removeLink.style.display = 'none';
            }
        }
    </script>
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnSave" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Save %>" />
            <Controls:DeleteButton ID="btnDelete" runat="server" CssClass="toolbtn" CausesValidation="False"></Controls:DeleteButton>
            <asp:Button ID="btnTestConnection" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, TestConnection %>" />
            <span class="tooldiv" id="divObjects" runat="server"></span>
            <asp:Button ID="btnObjects" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, DataObjects %>" />
            <span class="tooldiv"></span>
            <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Back %>" CausesValidation="false" />
        </div>
        <div class="body">
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <table align="center" class="editsection" cellspacing="0" role="presentation">
                <tr>
                    <td>
                        <span class="m">*</span><asp:Label ID="lblName" runat="server" Text="<%$Resources:Strings, DataSourceName %>"
                            AssociatedControlID="txtName"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtName" runat="server" MaxLength="100" CssClass="fld"></asp:TextBox><asp:RequiredFieldValidator
                            ID="valName" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtName"
                            CssClass="wrn"></asp:RequiredFieldValidator>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblConnectionType" runat="server" Text="<%$Resources:Strings, ConnectionType %>"
                            AssociatedControlID="lstConnectionType"></asp:Label>
                    </td>
                    <td>
                        <asp:DropDownList ID="lstConnectionType" runat="server" CssClass="fld" AutoPostBack="true">
                        </asp:DropDownList>
                    </td>
                </tr>
                <tr id="rowId" runat="server">
                    <td>
                        <asp:Label ID="lblId" runat="server" Text="<%$Resources:Strings, ID %>"></asp:Label>
                    </td>
                    <td>
                        <asp:Label ID="lblDataServiceGuid" runat="server" Text=""></asp:Label>
                    </td>
                </tr>
                <tr id="dseConnectionAttributes" runat="server">
                    <td>
                        <asp:Label ID="lblConnectionAttributes" runat="server" Text="<%$Resources:Strings, ConnectionAttributes %>" AssociatedControlID="txtConnectionAttributes"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtConnectionAttributes" runat="server" CssClass="fld" TextMode="MultiLine" Rows="6"></asp:TextBox>
                        <br />

                    </td>
                </tr>
                <tr id="dseSchema" runat="server">
                    <td>
                        <asp:Label ID="lblSchema" runat="server" Text="<%$Resources:Strings, Schema %>" AssociatedControlID="filSchema"></asp:Label>
                    </td>
                    <td>
                        <asp:HyperLink ID="hypSchemaDownload" runat="server" Text="<%$Resources:Strings, Download %>" class="dataSourceDownload" />
                        <asp:Label ID="lblSchemaFileName" runat="server" AssociatedControlID="filSchema" />
                        <asp:LinkButton ID="lnkSchemaRemove" runat="server" Text="<%$Resources:Strings, Remove %>" class="dataSourceDownload" />
                        <asp:LinkButton ID="lnkSchemaUpload" runat="server" Text="<%$Resources:Strings, Upload %>" OnClientClick="showSchemaDialog(); return false;" class="dataSourceDownload" />

                        <asp:FileUpload ID="filSchema" runat="server" Style="display: none;" onchange="newSchemaUpload(this)" />
                        <asp:HiddenField ID="hdnRemoveSchema" runat="server" Value="false" />
                    </td>

                </tr>
                <tr id="dseDefaultData" runat="server">
                    <td>
                        <asp:Label ID="lblDefaultData" runat="server" Text="<%$Resources:Strings, DefaultData %>" AssociatedControlID="filDefaultData"></asp:Label>
                    </td>
                    <td>
                        <asp:HyperLink ID="hypDefaultDataDownload" runat="server" Text="<%$Resources:Strings, Download %>" class="dataSourceDownload" />
                        <asp:Label ID="lblDefaultDataFileName" runat="server" AssociatedControlID="filDefaultData" />
                        <asp:LinkButton ID="lnkDefaultDataRemove" runat="server" Text="<%$Resources:Strings, Remove %>" class="dataSourceDownload" />
                        <asp:LinkButton ID="lnkDefaultDataUpload" runat="server" Text="<%$Resources:Strings, Upload %>" OnClientClick="showDefaultDataDialog(); return false;" class="dataSourceDownload" />

                        <asp:FileUpload ID="filDefaultData" runat="server" Style="display: none;" onchange="newDefaultDataUpload(this)" />
                        <asp:HiddenField ID="hdnRemoveDefaultData" runat="server" Value="false" />
                    </td>
                </tr>
                <tr id="dseExportConnectionAttributes" runat="server">
                    <td></td>
                    <td>
                        <asp:CheckBox ID="chkExportConnectionAttributes" runat="server" Text="<%$Resources:Strings, ExportConnectionAttributes %>" />
                        <div class="tooltip">
                            <div class="question-svg"></div>
                            <span class="tooltiptext">
                                <asp:Label ID="lblExportConnectionAttributesHelp" runat="server" /></span>
                        </div>
                    </td>
                </tr>
                <tr id="dseExportDefaultData" runat="server">
                    <td></td>
                    <td>
                        <asp:CheckBox ID="chkExportDefaultData" runat="server" Text="<%$Resources:Strings, ExportDefaultData %>" Checked="true" />
                        <div class="tooltip">
                            <div class="question-svg"></div>
                            <span class="tooltiptext">
                                <asp:Label ID="lblExportDefaultDataHelp" runat="server" /></span>
                        </div>
                    </td>
                </tr>
                <tr class="dseCredentials" id="dseCredentials" runat="server">
                    <th colspan="2">
                        <%=Resources.Strings.Credentials %>
                    </th>
                </tr>
                <tr class="dseCredentials" id="dseCredentialsOptions" runat="server">
                    <td colspan="2">
                        <asp:RadioButton ID="optConnectWithProvided" runat="server" GroupName="Auth" Text="<%$Resources:Strings, ConnectWithProvided %>" /><br />
                        <table style="margin-left: 12px" role="presentation" id="tblUsernameAndPassword" runat="server">
                            <tr>
                                <td>
                                    <asp:Label ID="lblUserName" runat="server" Text="<%$Resources:Strings, UserName %>"></asp:Label>
                                </td>
                                <td>
                                    <asp:TextBox ID="txtUserName" runat="server" CssClass="fld"></asp:TextBox>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <asp:Label ID="lblPassword" runat="server" Text="<%$Resources:Strings, Password %>"></asp:Label>
                                </td>
                                <td>
                                    <asp:TextBox ID="txtPassword" runat="server" TextMode="Password" CssClass="fld"></asp:TextBox>
                                </td>
                            </tr>
                        </table>
                        <asp:RadioButton ID="optWindowsAuthentication" runat="server" GroupName="Auth" Text="<%$Resources:Strings, WindowsAuthentication %>" /><br />
                        <asp:RadioButton ID="optAccessToken" runat="server" GroupName="Auth" Text="<%$Resources:Strings, AccessToken %>" /><br />
                        <asp:RadioButton ID="optNoCredentials" runat="server" GroupName="Auth" Text="<%$Resources:Strings, NoCredentials %>" />
                    </td>
                </tr>
            </table>
        </div>
    </div>
</asp:Content>
