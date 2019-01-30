<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.DataObjectEdit" CodeBehind="DataObjectEdit.aspx.vb" %>

<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <script src="Scripts/jquery-3.1.1.min.js" type="text/javascript"></script>
    <script src="Scripts/jquery-ui-1.12.1.custom.min.js" type="text/javascript"></script>
    <script src="Scripts/dataObject.js?v=10.0.32" type="text/javascript"></script>
    <script type="text/javascript">
        $(function () {
            var dsGuid = <%=Microsoft.Security.Application.Encoder.JavaScriptEncode(Request.QueryString("DataSourceId")) %>;

            $("#txtName").autocomplete({
                source: "DataObjectList.ashx?DataSourceId=" + dsGuid + "&objectType=" + $("#lstObjectType").val()
            });
        });

        $(document).ready(function () {
            infinitiDatasource();
        });
    </script>
    <link href="Content/jquery-ui-1.12.1.custom.css" rel="stylesheet" type="text/css" />
    <style>
        .fullwidth {
            width: 100%;
        }
    </style>
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnSave" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Save %>" />
            <Controls:DeleteButton ID="btnDelete" runat="server" CssClass="toolbtn" CausesValidation="False"></Controls:DeleteButton>
            <span class="tooldiv"></span>
            <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Back %>"
                CausesValidation="false" />
        </div>
        <div class="body">
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <div class="warningmsg" id="fieldWarning" visible="false" runat="server"></div>

            <input type="hidden" id="hidFilterFields" name="hidFilterFields" />
            <input type="hidden" id="hidSchemaFields" name="hidSchemaFields" />
            <input type="hidden" id="hidDisplayFields" name="hidDisplayFields" />
            <asp:CustomValidator ID="valSchemaFields" runat="server" Display="Dynamic" ClientValidationFunction="validateSchemaFields" CssClass="wrn"></asp:CustomValidator>
            <asp:CustomValidator ID="valDisplayFields" runat="server" Display="Dynamic" ClientValidationFunction="validateDisplayFields" CssClass="wrn"></asp:CustomValidator>
            <table align="center" class="editsection" cellspacing="0" role="presentation">
                <tr>
                    <td>
                        <asp:Label ID="lblObjectType" runat="server" Text="<%$Resources:Strings, ObjectType %>"
                            AssociatedControlID="lstObjectType"></asp:Label></td>
                    <td>
                        <asp:DropDownList ID="lstObjectType" runat="server" CssClass="fld" AutoPostBack="true" ClientIDMode="Static">
                        </asp:DropDownList></td>
                </tr>
                <tr class="dataObjectName">
                    <td>
                        <span class="m">*</span><asp:Label ID="lblName" runat="server" Text="<%$Resources:Strings, DataObjectName %>"
                            AssociatedControlID="txtName"></asp:Label></td>
                    <td>
                        <asp:TextBox ID="txtName" runat="server" CssClass="fld" Rows="10" Width="540px" ClientIDMode="Static"></asp:TextBox>
                        <asp:RequiredFieldValidator ID="valName" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtName" CssClass="wrn"></asp:RequiredFieldValidator>
                    </td>
                </tr>
                <tr>
                    <td>
                        <span class="m">*</span><asp:Label ID="lblDisplayObjectName" runat="server" Text="<%$Resources:Strings, DisplayName %>"
                            AssociatedControlID="txtDisplayObjectName"></asp:Label></td>
                    <td>
                        <asp:TextBox ID="txtDisplayObjectName" runat="server" MaxLength="500" CssClass="fld" Rows="10" Width="540px"></asp:TextBox><asp:RequiredFieldValidator
                            ID="valDisplay" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtDisplayObjectName" CssClass="wrn"></asp:RequiredFieldValidator></td>
                </tr>
                <tr id="trMergeSource" runat="server" visible="false">
                    <td>
                        <asp:Label ID="lblMergeSource" runat="server" Text="<%$Resources:Strings, MergeSource %>"
                            AssociatedControlID="chkMergeSource"></asp:Label></td>
                    <td>
                        <asp:CheckBox ID="chkMergeSource" runat="server" CssClass="fld"></asp:CheckBox></td>
                </tr>
                <tr id="trCache" runat="server">
                    <td>
                        <asp:Label ID="lblAllowCache" runat="server" Text="<%$Resources:Strings, MobileCache %>"></asp:Label>
                        <div class="tooltip">
                            <div class="question-svg"></div>
                            <span class="tooltiptext">
                                <asp:Label ID="lblMobileChaceHelp" runat="server" Text="<%$Resources:Strings, MobileCacheHelp %>"></asp:Label></span>
                        </div>
                    </td>
                    <td>
                        <asp:CheckBox ID="chkAllowCache" runat="server" CssClass="fld"></asp:CheckBox>
                    </td>
                </tr>
                <tr id="trRefreshRate" runat="server">
                    <td>
                        <asp:Label ID="lblCacheRefreshRate" runat="server" Text="<%$Resources:Strings, RefreshRate %>"></asp:Label>

                    </td>
                    <td>
                        <asp:TextBox ID="txtRefreshRate" runat="server" CssClass="fld" Width="100px"></asp:TextBox>
                        <asp:CustomValidator ID="valCacheDuration" ErrorMessage="<%$Resources:Strings, InvalidTime %>" runat="server" Display="Dynamic" ControlToValidate="txtRefreshRate" OnServerValidate="ValidateTimeSpan" CssClass="wrn"></asp:CustomValidator>
                        <label>(DD:HH:MM)</label>
                    </td>
                </tr>
                <tr id="trCacheWarning" runat="server">
                    <td>
                        <asp:Label ID="lblCacheWarning" runat="server" Text="<%$Resources:Strings, CacheWarning %>"></asp:Label>

                    </td>
                    <td>
                        <asp:TextBox ID="txtCacheWarning" runat="server" CssClass="fld" Width="100px"></asp:TextBox>
                        <asp:CustomValidator ID="valCacheWarning" ErrorMessage="<%$Resources:Strings, InvalidTime %>" runat="server" Display="Dynamic" ControlToValidate="txtCacheWarning" OnServerValidate="ValidateTimeSpan" CssClass="wrn"></asp:CustomValidator>
                        <label>(DD:HH:MM) - </label>
                        <asp:Label ID="lblCacheWarningMessage" runat="server" Text="<%$Resources:Strings, WarningMessage %>"></asp:Label>
                        <asp:TextBox ID="txtCacheWarningMessage" runat="server" CssClass="fld" Width="272px"></asp:TextBox>
                    </td>
                </tr>
                <tr id="trCacheExpiry" runat="server">
                    <td>
                        <asp:Label ID="lblCacheExpiry" runat="server" Text="<%$Resources:Strings, Expiry %>"></asp:Label>
                        <div class="tooltip">
                            <div class="question-svg"></div>
                            <span class="tooltiptext">
                                <asp:Label ID="lblCacheExpiryHelp" runat="server" Text="<%$Resources:Strings, CacheExpiryHelp %>"></asp:Label></span>
                        </div>
                    </td>
                    <td>
                        <asp:TextBox ID="txtCacheExpiry" runat="server" CssClass="fld" Width="100px"></asp:TextBox>
                        <asp:CustomValidator ID="valVacheExpiry" ErrorMessage="<%$Resources:Strings, InvalidTime %>" runat="server" Display="Dynamic" ControlToValidate="txtCacheExpiry" OnServerValidate="ValidateTimeSpan" CssClass="wrn"></asp:CustomValidator>
                        <label>(DD:HH:MM)</label>
                    </td>
                </tr>
                <tr id="trCacheUseAnswerFile" runat="server">
                    <td>
                        <asp:Label ID="lblCacheUseAnswerFile" runat="server" Text="<%$Resources:Strings, CacheUseAnswerFile %>"></asp:Label>
                        <div class="tooltip">
                            <div class="question-svg"></div>
                            <span class="tooltiptext">
                                <asp:Label ID="lblAnswerFileDataHelp" runat="server" Text="<%$Resources:Strings, AnswerFileDataHelp %>"></asp:Label></span>
                        </div>
                    </td>
                    <td>
                        <asp:CheckBox ID="chkUseAnswerFileData" runat="server" CssClass="fld"></asp:CheckBox>
                    </td>
                </tr>
            </table>

            <br />
            <br />
            <table align="center" class="editsection layoutgrd" cellspacing="0" id="tblFilterFields" runat="server" role="presentation">
                <tr>
                    <th><%=Resources.Strings.AvailableFilterFields %></th>
                    <th></th>
                    <th><%=Resources.Strings.FilterFields %></th>
                </tr>
                <tr>
                    <td valign="top">
                        <div class="fld" style="height: 200px; width: 300px; overflow: auto; background-color: white">
                            <select id="lstAvailableFilterFields" runat="server" enableviewstate="false" clientidmode="Static" size="14" onclick="availableFilterFieldsClick(this)" style="min-width: 300px"></select>
                        </div>
                    </td>
                    <td style="width: 120px">
                        <input type="button" id="btnAdd" class="toolbtn fullwidth" value="<%:Resources.Strings.AddArrow%>" onclick="addFilterField()" /><br />
                        <input type="button" id="btnAddAll" disabled="disabled" class="toolbtn fullwidth" value="<%:Resources.Strings.AddAll%>" onclick="addAllFilterFields()" /><br />
                        <input type="button" id="btnAddCustom" class="toolbtn fullwidth" value="<%:Resources.Strings.AddCustom%>" onclick="window.open('DataObjectCustom.aspx', '', 'height=100,width=100')" /><br />
                        <br />
                        <input type="button" id="btnRemove" disabled="disabled" class="toolbtn fullwidth" value="<%:Resources.Strings.RemoveArrow%>" onclick="removeFilterField()" /><br />
                        <input type="button" id="btnRemoveAll" disabled="disabled" class="toolbtn fullwidth" value="<%:Resources.Strings.RemoveAll %>" onclick="removeAllFilterFields()" />
                    </td>
                    <td>
                        <div class="fld" style="height: 200px; width: 300px; overflow: auto; background-color: white">
                            <select id="lstFilterFields" runat="server" enableviewstate="false" clientidmode="Static" size="14" onchange="filterFieldsClick(this)" style="min-width: 300px"></select>
                        </div>
                        <br />
                        <input type="checkbox" id="chkRequired" onclick="updateDisplay()" /><label for="chkRequired"><%:Resources.Strings.Required%></label><br />
                        <input type="checkbox" id="chkDisplay" onclick="updateDisplay()" /><label for="chkDisplay"><%:Resources.Strings.DisplayFilter %></label><br />
                        <label for="txtDisplayFilterName"><%:Resources.Strings.DisplayName%></label><br />
                        <input type="text" id="txtDisplayFilterName" class="fld" maxlength="500" onblur="updateDisplay()" style="width: 300px" />
                    </td>
                </tr>
            </table>
            <br />
            <table align="center" class="editsection layoutgrd" cellspacing="0" id="tblSchemaFields" runat="server" role="presentation">
                <tr>
                    <th><%=Resources.Strings.AvailableSchemaFields%></th>
                    <th></th>
                    <th><%=Resources.Strings.SchemaFields%></th>
                </tr>
                <tr>
                    <td valign="top">
                        <div class="fld" style="height: 200px; width: 300px; overflow: auto; background-color: white">
                            <select id="lstAvailableSchemaFields" runat="server" enableviewstate="false" clientidmode="Static" size="14" onchange="availableSchemaFieldsClick(this)" style="min-width: 300px"></select>
                        </div>
                    </td>
                    <td style="width: 120px;">
                        <input type="button" id="btnAddSchema" disabled="disabled" class="toolbtn fullwidth" value="<%:Resources.Strings.AddArrow%>" onclick="addSchemaField()" /><br />
                        <input type="button" id="btnAddAllSchema" disabled="disabled" class="toolbtn fullwidth" value="<%:Resources.Strings.AddAll %>" onclick="addAllSchemaFields()" /><br />
                        <br />
                        <input type="button" id="btnRemoveSchema" disabled="disabled" class="toolbtn fullwidth" value="<%:Resources.Strings.RemoveArrow%>" onclick="removeSchemaField()" /><br />
                        <input type="button" id="btnRemoveAllSchema" disabled="disabled" class="toolbtn fullwidth" value="<%:Resources.Strings.RemoveAll %>" onclick="removeAllSchemaFields()" />
                    </td>
                    <td>
                        <div class="fld" style="height: 200px; width: 300px; overflow: auto; background-color: white">
                            <select id="lstSchemaFields" runat="server" enableviewstate="false" clientidmode="Static" size="14" onchange="schemaFieldsClick(this)" style="min-width: 300px"></select>
                        </div>
                    </td>
                </tr>
            </table>
            <br />
            <table align="center" class="editsection layoutgrd" cellspacing="0" id="tblDisplayFields" runat="server" role="presentation">
                <tr>
                    <th><%=Resources.Strings.AvailableDisplayFields%></th>
                    <th></th>
                    <th><%=Resources.Strings.DisplayFields%></th>
                </tr>
                <tr>
                    <td valign="top">
                        <div class="fld" style="height: 200px; width: 300px; overflow: auto; background-color: white">
                            <select id="lstAvailableDisplayFields" runat="server" enableviewstate="false" clientidmode="Static" size="14" onchange="availableDisplayFieldsClick(this)" style="min-width: 300px"></select>
                        </div>
                    </td>
                    <td style="width: 120px;">
                        <input type="button" id="btnAddDisplay" disabled="disabled" class="toolbtn fullwidth" value="<%:Resources.Strings.AddArrow%>" onclick="addDisplayField()" /><br />
                        <input type="button" id="btnAddAllDisplay" disabled="disabled" class="toolbtn fullwidth" value="<%:Resources.Strings.AddAll %>" onclick="addAllDisplayFields()" /><br />
                        <br />
                        <input type="button" id="btnRemoveDisplay" disabled="disabled" class="toolbtn fullwidth" value="<%:Resources.Strings.RemoveArrow%>" onclick="removeDisplayField()" /><br />
                        <input type="button" id="btnRemoveAllDisplay" disabled="disabled" class="toolbtn fullwidth" value="<%:Resources.Strings.RemoveAll %>" onclick="removeAllDisplayFields()" />
                    </td>
                    <td>
                        <div class="fld" style="height: 200px; width: 300px; overflow: auto; background-color: white">
                            <select id="lstDisplayFields" runat="server" enableviewstate="false" clientidmode="Static" size="14" onchange="displayFieldsClick(this)" style="min-width: 300px"></select>
                        </div>
                        <br />
                        <label for="txtDisplayFieldName"><%:Resources.Strings.DisplayName%></label><br />
                        <input type="text" id="txtDisplayFieldName" class="fld" maxlength="500" onblur="updateDisplayFieldName()" style="width: 300px" />
                    </td>
                </tr>
            </table>
        </div>
        <script type="text/javascript">
            setFilterButtonState()
            setFilterListHeight();
            setSchemaButtonState()
            setSchemaListHeight();
            setDisplayButtonState()
            setDisplayListHeight();
            showDisplay();
        </script>
    </div>
</asp:Content>

